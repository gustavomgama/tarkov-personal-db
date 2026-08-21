class HideoutStation < ApplicationRecord
  DISPLAY_NAMES = YAML.safe_load(
    Rails.root.join("config/hideout_station_names.yml").read
  ).freeze

  has_many :hideout_levels, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
