class Trader < ApplicationRecord
  has_many :trader_items, dependent: :destroy
  has_many :items, through: :trader_items
  has_many :tasks, dependent: :nullify

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
  validates :currency, presence: true
end
