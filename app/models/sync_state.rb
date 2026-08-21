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
