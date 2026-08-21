class TaskObjective < ApplicationRecord
  belongs_to :task
  belongs_to :item

  validates :task_id, uniqueness: { scope: :item_id }
end
