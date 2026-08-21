require "test_helper"

class SyncStateTest < ActiveSupport::TestCase
  test "records syncs and reports the last synced version" do
    assert_nil SyncState.last_synced_version

    SyncState.record_sync!("1.0.0.1.1")
    travel_to(1.minute.from_now) { SyncState.record_sync!("1.1.0.1.46911") }

    assert_equal "1.1.0.1.46911", SyncState.last_synced_version
  end
end
