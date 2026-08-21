class TraderItem < ApplicationRecord
  belongs_to :trader
  belongs_to :item
  belongs_to :unlock_task, class_name: "Task", optional: true

  validates :trader_id, uniqueness: { scope: :item_id }
end
