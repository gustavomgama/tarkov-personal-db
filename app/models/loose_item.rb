# == Schema Information
#
# Table name: loose_items
#
#  id        :bigint           not null, primary key
#  reward_id :bigint
#  item_id   :string
#  item_name :string
#  count     :integer
#
# Indexes
#
#  index_loose_items_on_reward_id  (reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (reward_id => rewards.id)
#
class LooseItem < ApplicationRecord
  belongs_to :reward, foreign_key: :reward_id
end
