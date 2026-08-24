# == Schema Information
#
# Table name: item_unlocks
#
#  id            :integer          not null, primary key
#  item_name     :string           not null
#  loyalty_level :integer
#  trader_name   :string
#  unlock_types  :text             default("[]"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  item_id       :integer          not null
#  task_id       :integer
#  trader_id     :integer
#
# Indexes
#
#  index_item_unlocks_item_task     (item_id,task_id)
#  index_item_unlocks_on_item_id    (item_id)
#  index_item_unlocks_on_task_id    (task_id)
#  index_item_unlocks_on_trader_id  (trader_id)
#
# Foreign Keys
#
#  item_id    (item_id => items.id)
#  task_id    (task_id => tasks.id)
#  trader_id  (trader_id => traders.id)
#
class ItemUnlock < ApplicationRecord
  serialize :unlock_types, coder: JSON

  belongs_to :item
  belongs_to :trader, optional: true
  belongs_to :task, optional: true

  validates :item_name, presence: true

  scope :of_type, ->(type) { where("unlock_types LIKE ?", "%\"#{type}\"%") }

  def self.for_item(item)
    where(item_id: item.id)
  end
end
