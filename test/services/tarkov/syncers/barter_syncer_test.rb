require "test_helper"

module Tarkov
  module Syncers
    class BarterSyncerTest < ActiveSupport::TestCase
      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
        TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
        Item.create!(tid: "item-2", name: "Dollars")
        Item.create!(tid: "qitem-9", name: "Intel")
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
                           source: "dev",
                           item_name: "Dollars")

        BarterSyncer.new(client: fake_client).call

        assert_nil ItemUnlock.find_by(loyalty_level: 9)
      end

      test "skips barters referencing unknown traders or items" do
        assert_no_difference("ItemUnlock.count") do
          BarterSyncer.new(client: FakeTarkovClient.new(barters: [ barter_payload.last ])).call
        end
      end

      test "empty upstream response never wipes stored barter rows" do
        BarterSyncer.new(client: fake_client).call

        assert_no_difference("ItemUnlock.of_type('barter').count") do
          assert_equal 0, BarterSyncer.new(client: FakeTarkovClient.new(barters: [], items: item_payload)).call
        end
      end

      test "syncs cash offers into money unlock rows with loyalty levels" do
        Item.find_by!(tid: "item-1-default").item_unlocks.of_type("money").destroy_all
        client = FakeTarkovClient.new(barters: [], items: item_payload)
        BarterSyncer.new(client: client).call

        rows = Item.find_by!(tid: "item-1-default").item_unlocks.of_type("money").order(:loyalty_level)
        assert_equal [ 2, 3 ], rows.map(&:loyalty_level)
        assert_equal [ "Prapor" ], rows.map(&:trader_name).uniq
        assert_predicate Item.find_by!(tid: "item-1-default").reload, :require_unlock?
      end

      test "records the source variant when an offer targets a folded preset" do
        barters = [
          { "id" => "barter-m4a1", "trader" => "trader-1", "minTraderLevel" => 3,
            "requiredItems" => [ { "item" => "item-2", "count" => 5 } ],
            "offeredItem" => { "item" => "item-1", "count" => 1 } }
        ]
        BarterSyncer.new(client: FakeTarkovClient.new(
          items: item_payload, barters: barters,
          localizations: { items: { "item-1 ShortName" => "M4A1" } }
        )).call

        keeper = Item.find_by!(tid: "item-1-default")
        row = keeper.item_unlocks.of_type("barter").sole

        assert_equal "M4A1", row.source_variant
      end

      test "GP-coin purchases become Ref-only money rows, not barters" do
        GP_TID = "5d235b4d86f7742e017bc88a"
        item = Item.create!(tid: "gp-item", name: "Ref Goodie")
        Item.create!(tid: GP_TID, name: "GP coin")
        barters = [
          { "id" => "gp-barter", "trader" => "trader-1", "minTraderLevel" => 2,
            "requiredItems" => [ { "item" => GP_TID, "count" => 10 } ],
            "offeredItem" => { "item" => "gp-item", "count" => 1 } }
        ]
        BarterSyncer.new(client: FakeTarkovClient.new(items: item_payload, barters: barters)).call

        row = Item.find_by!(tid: "gp-item").item_unlocks.sole
        assert_equal [ "money" ], Array(row.unlock_types)
        assert_equal "GP", row.currency
        assert_predicate Item.find_by!(tid: "gp-item"), :ref_gp?
      end

      private

      def fake_client
        FakeTarkovClient.new(barters: barter_payload, items: item_payload)
      end
    end
  end
end
