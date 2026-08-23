require "test_helper"

module Tarkov
  module Syncers
    class ItemSyncerTest < ActiveSupport::TestCase
      test "creates items with slim attribute set" do
        count = ItemSyncer.new(client: fake_client).call

        assert_equal 1, count
        item = Item.find_by!(tid: "item-1")
        assert_equal "Colt M4A1", item.name
        assert_equal "https://assets.tarkov.dev/item-1-icon.webp", item.icon_link
        assert_equal 70, item.price.to_f
        assert_equal "USD", item.currency
        assert_not item.barter?
        assert_not item.craft?
        assert_not item.require_unlock?
      end

      test "is idempotent on re-run" do
        syncer = ItemSyncer.new(client: fake_client)
        syncer.call
        assert_no_difference("Item.count") { syncer.call }
      end

      private

      def fake_client
        FakeTarkovClient.new(items: item_payload)
      end
    end
  end
end
