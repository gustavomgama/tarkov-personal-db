require "test_helper"

module Tarkov
  module Syncers
    class TaskSyncerTest < ActiveSupport::TestCase
      setup do
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        @count = TaskSyncer.new(client: fake_client).call
      end

      test "creates tasks linked to trader with flags" do
        assert_equal 2, @count
        task = Task.find_by!(tid: "task-1")
        assert_equal "Supplier", task.name
        assert_equal "trader-1", task.trader.tid
        assert_equal 5, task.min_player_level
        assert_predicate task, :kappa_required?
        assert_predicate task, :lightkeeper_required?

        assert_nil Task.find_by!(tid: "task-2").trader
      end

      test "creates money unlock rows from finishRewards offerUnlock" do
        item = Item.find_by!(tid: "item-1-default")
        row = item.item_unlocks.of_type("money").sole
        assert_equal "Prapor", row.trader_name
        assert_equal 4, row.loyalty_level
        assert_equal Task.find_by!(tid: "task-1"), row.task
        assert_predicate item.reload, :require_unlock?
      end

      test "creates reward rows from finishRewards items" do
        Item.create!(tid: "item-2", name: "Dollars") # reward target from the payload
        TaskSyncer.new(client: fake_client).call

        rewarded = Item.find_by!(tid: "item-2")
        row = rewarded.item_unlocks.of_type("reward").sole

        assert_equal Task.find_by!(tid: "task-1"), row.task
        assert_equal [ "reward" ], row.unlock_types
      end

      test "skips tasks whose localized name is historical content" do
        client = FakeTarkovClient.new(
          tasks: { "tasks" => { "task-hist" => { "id" => "task-hist", "name" => "Bloodhounds (quest)",
                                                 "normalizedName" => "bloodhounds-quest", "trader" => nil } } },
          localizations: { tasks: { "task-hist name" => "Bloodhounds (quest)" } }
        )

        assert_equal 0, TaskSyncer.new(client: client).call
        assert_nil Task.find_by(tid: "task-hist")
      end

      private

      def fake_client
        FakeTarkovClient.new(tasks: tasks_payload)
      end
    end
  end
end
