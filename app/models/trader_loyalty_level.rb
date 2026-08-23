# == Schema Information
#
# Table name: trader_loyalty_levels
#
#  id                    :integer          not null, primary key
#  level                 :integer          not null
#  required_player_level :integer
#  required_reputation   :decimal(8, 2)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  trader_id             :integer          not null
#
# Indexes
#
#  index_trader_loyalty_levels_on_trader_id            (trader_id)
#  index_trader_loyalty_levels_on_trader_id_and_level  (trader_id,level) UNIQUE
#
# Foreign Keys
#
#  trader_id  (trader_id => traders.id)
#
class TraderLoyaltyLevel < ApplicationRecord
  attribute :required_reputation, :float

  belongs_to :trader

  validates :level, presence: true, uniqueness: { scope: :trader_id }
end
