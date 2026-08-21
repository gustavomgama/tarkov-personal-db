class HideoutCraft < ApplicationRecord
  KINDS = %w[required reward].freeze

  belongs_to :hideout_station
  has_many :craft_items, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
end
