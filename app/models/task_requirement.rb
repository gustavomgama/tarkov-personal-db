# == Schema Information
#
# Table name: task_requirements
#
#  id               :integer          not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  required_task_id :integer          not null
#  task_id          :integer          not null
#
# Indexes
#
#  index_task_requirements_on_required_task_id              (required_task_id)
#  index_task_requirements_on_task_id                       (task_id)
#  index_task_requirements_on_task_id_and_required_task_id  (task_id,required_task_id) UNIQUE
#
# Foreign Keys
#
#  required_task_id  (required_task_id => tasks.id)
#  task_id           (task_id => tasks.id)
#
class TaskRequirement < ApplicationRecord
  belongs_to :task
  belongs_to :required_task, class_name: "Task"

  validates :task_id, uniqueness: { scope: :required_task_id }
end
