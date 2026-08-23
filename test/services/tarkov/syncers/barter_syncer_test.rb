require "test_helper"

module Tarkov
  module Syncers
    class BarterSyncerTest < ActiveSupport::TestCase
      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
        TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
        Item.create!(tid: "item-2", name: "Dollars")
        @trader = Trader.find_by!(tid: "trader-1")
      end

      test "creates barter unlock rows with trader and task references" do
        count = BarterSyncer.new(client: fake_client).call

        assert_equal 2, count
        cash = Item.find_by!(tid: "item-2").item_unlocks.of_type("money")
        assert_empty cash
        unlocked = Item.find_by!(tid: "qitem-9").item_unlocks.of_type("barter").sole
        assert_equal "barter", unlocked.unlock_types.first
        assert_equal @trader, unlocked.trader
        assert_equal "Prapor", unlocked.trader_name
        assert_equal 4, unlocked.loyalty_level
        assert_equal Task.find_by!(tid: "task-1"), unlocked.task

        plain = Item.find_by!(tid: "item-2").item_unlocks.sole
        assert_nil plain.task_id
        assert_predicate Item.find_by!(tid: "qitem-9").reload, :barter?
        assert_predicate Item.find_by!(tid: "item-2").reload, :barter?
      end

      test "keeps one row per loyalty level when a trader offers multiple" do
        barters = barter_payload + [ barter_payload.first.merge("id" => "barter-low", "minTraderLevel" => 1) ]
        count = BarterSyncer.new(client: FakeTarkovClient.new(barters: barters)).call

        levels = Item.find_by!(tid: "item-2").item_unlocks.of_type("barter").map(&:loyalty_level).sort
        assert_equal [ 1, 2 ], levels
        assert_equal 3, count
      end

      test "destroys stale barter rows missing from payload" do
        BarterSyncer.new(client: fake_client).call
        ItemUnlock.create!(item: Item.find_by!(tid: "item-2"), trader: @trader,
                           trader_name: "Prapor", loyalty_level: 9, unlock_types: [ "barter" ],
                           item_name: "Dollars")

        BarterSyncer.new(client: fake_client).call

        assert_nil ItemUnlock.find_by(loyalty_level: 9)
      end

      test "skips barters referencing unknown traders or items" do
        assert_no_difference("ItemUnlock.count") do
          BarterSyncer.new(client: FakeTarkovClient.new(barters: [ barter_payload.last ])).call
        end
      end

      test "syncs cash offers into money unlock rows with loyalty levels" do
        client = FakeTarkovClient.new(barters: [], items: item_payload)
        BarterSyncer.new(client: client).call

        rows = Item.find_by!(tid: "item-1").item_unlocks.of_type("money").order(:loyalty_level)
        assert_equal [ 2, 3 ], rows.map(&:loyalty_level)
        assert_equal [ "Prapor" ], rows.map(&:trader_name).uniq
        assert_not_predicate Item.find_by!(tid: "item-1").reload, :require_unlock?
      end

      private

      def fake_client
        FakeTarkovClient.new(barters: barter_payload, items: item_payload)
      end
    end
  end
end
