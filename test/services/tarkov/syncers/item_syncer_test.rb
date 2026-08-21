require "test_helper"

module Tarkov
  module Syncers
    class ItemSyncerTest < ActiveSupport::TestCase
      test "creates items with attributes, types and resolved category" do
        count = ItemSyncer.new(client: fake_client).call

        assert_equal 1, count
        item = Item.find_by!(tid: "item-1")
        assert_equal "Colt M4A1", item.name
        assert_equal "M4A1", item.short_name
        assert_equal "assault-rifle", item.category
        assert_equal [ "gun" ], item.types
        assert_equal 4, item.width
        assert_equal 2, item.height
        assert_in_delta 3.1, item.weight.to_f
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
