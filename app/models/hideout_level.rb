class HideoutLevel < ApplicationRecord
  belongs_to :hideout_station
  has_many :hideout_item_requirements, dependent: :destroy
  has_many :items, through: :hideout_item_requirements
  has_many :hideout_requirements, dependent: :destroy

  validates :level, presence: true
  validates :level, uniqueness: { scope: :hideout_station_id }
end
