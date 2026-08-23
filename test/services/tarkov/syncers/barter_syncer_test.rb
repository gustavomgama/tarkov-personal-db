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
        unlocked = Item.find_by!(tid: "qitem-9").item_unlocks.sole
        assert_equal "barter", unlocked.unlock_types.first
        assert_equal @trader, unlocked.trader
        assert_equal 4, unlocked.loyalty_level
        assert_equal Task.find_by!(tid: "task-1"), unlocked.task

        plain = Item.find_by!(tid: "item-2").item_unlocks.sole
        assert_nil plain.task_id
        assert_predicate Item.find_by!(tid: "qitem-9").reload, :barter?
        assert_predicate Item.find_by!(tid: "item-2").reload, :barter?
      end

      test "skips barters referencing unknown traders or items" do
        assert_no_difference("ItemUnlock.count") do
          BarterSyncer.new(client: FakeTarkovClient.new(barters: [ barter_payload.last ])).call
        end
      end

      private

      def fake_client
        FakeTarkovClient.new(barters: barter_payload)
      end
    end
  end
end
