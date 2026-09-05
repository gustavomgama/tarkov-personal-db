# == Schema Information
#
# Table name: offer_unlocks
#
#  id           :bigint           not null, primary key
#  reward_id    :bigint
#  item_id      :string
#  item_name    :string
#  trader_name  :string
#  trader_level :string
#
# Indexes
#
#  index_offer_unlocks_on_reward_id  (reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (reward_id => rewards.id)
#
class OfferUnlock < ApplicationRecord
  belongs_to :reward, foreign_key: :reward_id
end
