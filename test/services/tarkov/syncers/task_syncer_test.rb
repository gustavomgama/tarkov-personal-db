require "test_helper"

module Tarkov
  module Syncers
    class TaskSyncerTest < ActiveSupport::TestCase
      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
      end

      test "creates tasks linked to trader with objectives from item references" do
        count = TaskSyncer.new(client: fake_client).call

        assert_equal 2, count
        task = Task.find_by!(tid: "task-1")
        assert_equal "Supplier", task.name
        assert_equal "trader-1", task.trader.tid
        assert_equal 5, task.min_player_level
        assert_predicate task, :kappa_required?

        objective = task.task_objectives.sole
        assert_equal "item-1", objective.item.tid
        assert_equal 3, objective.count
        assert_predicate objective, :found_in_raid?
      end

      test "creates tasks without trader when payload has none" do
        TaskSyncer.new(client: fake_client).call

        task = Task.find_by!(tid: "task-2")
        assert_nil task.trader
      end

      test "warns and skips objectives referencing unknown items" do
        TaskSyncer.new(client: fake_client).call

        assert_nothing_raised do
          Task.find_by!(tid: "task-1").task_objectives.reload
        end
        assert_equal [ "item-1" ], Task.find_by!(tid: "task-1").task_objectives.includes(:item).map { |o| o.item.tid }
      end

      private

      def fake_client
        FakeTarkovClient.new(tasks: tasks_payload)
      end
    end
  end
end
