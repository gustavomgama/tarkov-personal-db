# == Schema Information
#
# Table name: hideout_levels
#
#  id                 :integer          not null, primary key
#  construction_time  :integer
#  description        :text
#  level              :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  hideout_station_id :integer          not null
#
# Indexes
#
#  index_hideout_levels_on_hideout_station_id            (hideout_station_id)
#  index_hideout_levels_on_hideout_station_id_and_level  (hideout_station_id,level) UNIQUE
#
# Foreign Keys
#
#  hideout_station_id  (hideout_station_id => hideout_stations.id)
#
class HideoutLevel < ApplicationRecord
  belongs_to :hideout_station
  has_many :hideout_item_requirements, dependent: :destroy
  has_many :items, through: :hideout_item_requirements
  has_many :hideout_requirements, dependent: :destroy

  validates :level, presence: true
  validates :level, uniqueness: { scope: :hideout_station_id }
end
