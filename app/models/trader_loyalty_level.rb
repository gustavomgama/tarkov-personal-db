class TraderLoyaltyLevel < ApplicationRecord
  belongs_to :trader

  validates :level, presence: true, uniqueness: { scope: :trader_id }
end
