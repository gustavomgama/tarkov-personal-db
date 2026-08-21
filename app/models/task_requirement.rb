class TaskRequirement < ApplicationRecord
  belongs_to :task
  belongs_to :required_task, class_name: "Task"

  validates :task_id, uniqueness: { scope: :required_task_id }
end
