class ItemUnlock < ApplicationRecord
  belongs_to :item

  validates :trader_title, presence: true
end
