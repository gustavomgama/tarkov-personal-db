# == Schema Information
#
# Table name: sync_states
#
#  id         :integer          not null, primary key
#  synced_at  :datetime         not null
#  version    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SyncState < ApplicationRecord
  validates :version, presence: true
  validates :synced_at, presence: true

  def self.last_synced_version
    order(:synced_at).last&.version
  end

  def self.record_sync!(version)
    create!(version: version, synced_at: Time.current)
  end
end
