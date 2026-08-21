require "test_helper"

module Tarkov
  module Syncers
    class TraderItemSyncerTest < ActiveSupport::TestCase
      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
        @item_2 = Item.create!(tid: "item-2", name: "Dollars")
      end

      test "creates trader items from barters" do
        count = TraderItemSyncer.new(client: fake_client).call

        assert_equal 1, count
        record = TraderItem.joins(:item).find_by!(items: { tid: "item-2" })
        assert_equal "trader-1", record.trader.tid
        assert_equal 2, record.min_trader_level
        assert_predicate record, :barter?
        assert_not_predicate record, :price?
      end

      test "skips barters referencing unknown traders or items" do
        assert_no_difference("TraderItem.count") do
          TraderItemSyncer.new(client: FakeTarkovClient.new(barters: [ barter_payload.second ])).call
        end
      end

      private

      def fake_client
        FakeTarkovClient.new(barters: barter_payload)
      end
    end
  end
end
