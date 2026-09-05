# == Schema Information
#
# Table name: barter_unlocks
#
#  id        :bigint           not null, primary key
#  reward_id :bigint
#  item_id   :string
#  item_name :string
#
# Indexes
#
#  index_barter_unlocks_on_reward_id  (reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (reward_id => rewards.id)
#
class BarterUnlock < ApplicationRecord
  belongs_to :reward, foreign_key: :reward_id
  has_many :barter_requirements, dependent: :destroy
  has_many :barter_results, dependent: :destroy
end
