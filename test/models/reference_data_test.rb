require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "validates tid uniqueness and name presence" do
    Item.create!(tid: "x", name: "Item")
    duplicate = Item.new(tid: "x", name: "Other")

    assert_predicate duplicate, :invalid?
    assert_not_empty duplicate.errors[:tid]

    anonymous = Item.new(tid: "y")
    assert_predicate anonymous, :invalid?
    assert_not_empty anonymous.errors[:name]
  end

  test "serializes types as JSON array" do
    item = Item.create!(tid: "x", name: "Item", types: %w[gun wearable])

    assert_equal %w[gun wearable], item.reload.types
  end
end

class TraderTest < ActiveSupport::TestCase
  test "defaults currency to RUB at the database level" do
    trader = Trader.create!(tid: "t", name: "Prapor")

    assert_equal "RUB", trader.currency
  end
end

class TaskObjectiveTest < ActiveSupport::TestCase
  test "uniqueness scoped to task and item" do
    trader = Trader.create!(tid: "t", name: "Prapor")
    task = Task.create!(tid: "task", name: "Task", trader: trader)
    item = Item.create!(tid: "item", name: "Item")
    TaskObjective.create!(task: task, item: item)

    duplicate = TaskObjective.new(task: task, item: item)

    assert_predicate duplicate, :invalid?
    assert_not_empty duplicate.errors[:task_id]
  end
end

class HideoutRequirementTest < ActiveSupport::TestCase
  test "requirement_type inclusion validation" do
    station = HideoutStation.create!(tid: "s", name: "Generator")
    level = station.hideout_levels.create!(level: 1)
    requirement = HideoutRequirement.new(hideout_level: level, requirement_type: "bogus", target_name: "X")

    assert_predicate requirement, :invalid?
    assert_not_empty requirement.errors[:requirement_type]
  end
end
