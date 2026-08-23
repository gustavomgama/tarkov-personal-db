# == Schema Information
#
# Table name: task_objectives
#
#  id            :integer          not null, primary key
#  count         :integer
#  found_in_raid :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  item_id       :integer          not null
#  task_id       :integer          not null
#
# Indexes
#
#  index_task_objectives_on_item_id              (item_id)
#  index_task_objectives_on_task_id              (task_id)
#  index_task_objectives_on_task_id_and_item_id  (task_id,item_id) UNIQUE
#
# Foreign Keys
#
#  item_id  (item_id => items.id)
#  task_id  (task_id => tasks.id)
#
class TaskObjective < ApplicationRecord
  belongs_to :task
  belongs_to :item

  validates :task_id, uniqueness: { scope: :item_id }
end
