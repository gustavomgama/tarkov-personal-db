require "test_helper"

module Tarkov
  module Syncers
    class ItemPurgeTest < ActiveSupport::TestCase
      test "removes items with no buy, barter, craft or task-gated path" do
        junk = Item.create!(tid: "junk-1", name: "Junk")
        priced = Item.create!(tid: "keep-1", name: "Priced", price: 100, currency: "RUB")
        craftable = Item.create!(tid: "keep-2", name: "Craftable", craft: true)
        barterable = Item.create!(tid: "keep-3", name: "Barterable", barter: true)
        gated = Item.create!(tid: "keep-4", name: "Gated", require_unlock: true)
        unlocked = Item.create!(tid: "keep-5", name: "Unlocked Row")
        ItemUnlock.create!(item: unlocked, item_name: unlocked.name,
                           unlock_types: [ "barter" ], source: "dev")

        removed = ItemPurge.new(client: FakeTarkovClient.new).call

        assert_not Item.exists?(junk.id)
        assert_equal 5, Item.where(id: [ priced, craftable, barterable, gated, unlocked ].map(&:id)).count
        assert_equal 1, removed
      end
    end
  end
end
