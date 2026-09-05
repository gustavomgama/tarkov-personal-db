# == Schema Information
#
# Table name: item_task_rewards
#
#  id          :bigint           not null, primary key
#  item_id     :bigint
#  task_id     :string
#  task_name   :string
#  reward_type :string
#
# Indexes
#
#  index_item_task_rewards_on_item_id  (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class ItemTaskReward < ApplicationRecord
  belongs_to :item, foreign_key: :item_id
end
