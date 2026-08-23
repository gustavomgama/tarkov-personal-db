# == Schema Information
#
# Table name: hideout_crafts
#
#  id                 :integer          not null, primary key
#  duration           :integer
#  level              :integer
#  tid                :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  hideout_station_id :integer          not null
#
# Indexes
#
#  index_hideout_crafts_on_hideout_station_id  (hideout_station_id)
#  index_hideout_crafts_on_tid                 (tid) UNIQUE
#
# Foreign Keys
#
#  hideout_station_id  (hideout_station_id => hideout_stations.id)
#
class HideoutCraft < ApplicationRecord
  KINDS = %w[required reward].freeze

  belongs_to :hideout_station
  has_many :craft_items, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
end
