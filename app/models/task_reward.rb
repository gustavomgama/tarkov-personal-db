# == Schema Information
#
# Table name: task_rewards
#
#  id         :integer          not null, primary key
#  count      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  item_id    :integer          not null
#  task_id    :integer          not null
#
# Indexes
#
#  index_task_rewards_on_item_id              (item_id)
#  index_task_rewards_on_task_id              (task_id)
#  index_task_rewards_on_task_id_and_item_id  (task_id,item_id) UNIQUE
#
# Foreign Keys
#
#  item_id  (item_id => items.id)
#  task_id  (task_id => tasks.id)
#
class TaskReward < ApplicationRecord
  belongs_to :task
  belongs_to :item

  validates :task_id, uniqueness: { scope: :item_id }
end
