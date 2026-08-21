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

        objective = task.task_objectives.joins(:item).find_by(items: { tid: "item-1" })
        assert_equal "item-1", objective.item.tid
        assert_equal 3, objective.count
        assert_predicate objective, :found_in_raid?
      end

      test "stores quest items as typed items linked via objectives" do
        TaskSyncer.new(client: fake_client).call

        quest_item = Item.find_by!(tid: "qitem-9")
        assert_equal [ "questItem" ], quest_item.types
        assert_equal "Military Intel", quest_item.name

        objective = Task.find_by!(tid: "task-1").task_objectives.find_by!(item: quest_item)
        assert_equal 2, objective.count
      end

      test "records lightkeeper and faction flags" do
        TaskSyncer.new(client: fake_client).call

        task = Task.find_by!(tid: "task-1")
        assert_predicate task, :lightkeeper_required?
        assert_equal "Any", task.faction_name
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
        tids = Task.find_by!(tid: "task-1").task_objectives.includes(:item).map { |o| o.item.tid }.sort
        assert_equal [ "item-1", "qitem-9" ], tids
      end

      private

      def fake_client
        FakeTarkovClient.new(tasks: tasks_payload)
      end
    end
  end
end
