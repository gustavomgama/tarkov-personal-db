# == Schema Information
#
# Table name: hideout_stations
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  normalized_name :string
#  tid             :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_hideout_stations_on_normalized_name  (normalized_name)
#  index_hideout_stations_on_tid              (tid) UNIQUE
#
class HideoutStation < ApplicationRecord
  DISPLAY_NAMES = YAML.safe_load(
    Rails.root.join("config/hideout_station_names.yml").read
  ).freeze

  has_many :hideout_levels, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
