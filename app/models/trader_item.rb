class TraderItem < ApplicationRecord
  belongs_to :trader
  belongs_to :item

  validates :trader_id, uniqueness: { scope: :item_id }
end
