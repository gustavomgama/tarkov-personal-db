require "test_helper"

module Tarkov
  module Syncers
    class HistoricalPurgeTest < ActiveSupport::TestCase
      test "removes retired tasks and items, images included" do
        task = Task.create!(tid: "hist-task", name: "Bloodhounds (quest)")
        item = Item.create!(tid: "hist-item", name: "SJ15 TGLabs combat stimulant injector",
                            slug: "sj15-tglabs-combat-stimulant-injector")
        ItemUnlock.create!(item: item, item_name: item.name, trader_name: "Ref",
                           unlock_types: [ "money" ], currency: "GP")
        image = Rails.root.join("public/images/items/hist-item-icon.webp")
        FileUtils.mkdir_p(image.dirname)
        File.write(image, "")

        removed_tasks, removed_items = HistoricalPurge.new(client: FakeTarkovClient.new).call

        assert_equal 1, removed_tasks
        assert_equal 1, removed_items
        assert_nil Task.find_by(id: task.id)
        assert_nil Item.find_by(id: item.id)
        assert_not File.exist?(image)
        # Cascade check: the retired item's unlock rows went with it.
        assert_empty ItemUnlock.where(item_id: item.id)
      end

      test "current content is untouched" do
        keep = Task.create!(tid: "live-task", name: "Supplier")

        HistoricalPurge.new(client: FakeTarkovClient.new).call

        assert Task.exists?(keep.id)
      end
    end
  end
end
