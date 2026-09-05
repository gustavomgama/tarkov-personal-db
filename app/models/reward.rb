# == Schema Information
#
# Table name: rewards
#
#  id          :bigint           not null, primary key
#  task_id     :bigint
#  reward_type :string
#
# Indexes
#
#  index_rewards_on_task_id  (task_id)
#
# Foreign Keys
#
#  fk_rails_...  (task_id => tasks.id)
#
class Reward < ApplicationRecord
  belongs_to :task, foreign_key: :task_id
  has_many :loose_items, dependent: :destroy
  has_many :offer_unlocks, dependent: :destroy
  has_many :barter_unlocks, dependent: :destroy
  has_many :craft_unlocks, dependent: :destroy
end
