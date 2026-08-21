class Item < ApplicationRecord
  serialize :types, coder: JSON

  has_many :trader_items, dependent: :destroy
  has_many :traders, through: :trader_items
  has_many :task_objectives, dependent: :destroy
  has_many :tasks, through: :task_objectives
  has_many :hideout_item_requirements, dependent: :destroy
  has_many :hideout_levels, through: :hideout_item_requirements
  has_many :item_unlocks, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
