class HideoutStation < ApplicationRecord
  has_many :hideout_levels, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
