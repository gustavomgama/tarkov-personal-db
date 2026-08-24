require "test_helper"

module Tarkov
  class GapCoverageTest < ActiveSupport::TestCase
    test "task falls back to previous_task_id when no requirements" do
      prev = Task.create!(tid: "gap-prev", name: "Prev Task")
      task = Task.create!(tid: "gap-task", name: "Current", previous_task_id: prev.id)

      assert_equal [ prev ], task.prerequisite_tasks.to_a
    end
  end
end
