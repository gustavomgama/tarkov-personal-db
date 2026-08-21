class Task < ApplicationRecord
  belongs_to :trader, optional: true

  has_many :task_objectives, dependent: :destroy
  has_many :items, through: :task_objectives

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
