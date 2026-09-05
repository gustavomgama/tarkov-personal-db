# == Schema Information
#
# Table name: craft_unlocks
#
#  id              :bigint           not null, primary key
#  reward_id       :bigint
#  item_id         :string
#  item_name       :string
#  hideout_station :string
#  station_level   :integer
#
# Indexes
#
#  index_craft_unlocks_on_reward_id  (reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (reward_id => rewards.id)
#
class CraftUnlock < ApplicationRecord
  belongs_to :reward, foreign_key: :reward_id
  has_many :craft_requirements, dependent: :destroy
  has_many :craft_results, dependent: :destroy
end
