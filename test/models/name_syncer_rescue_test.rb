require "test_helper"

class NameSyncerRescueTest < ActiveSupport::TestCase
  test "apply_name survives invalid trader updates" do
    trader = Trader.create!(tid: "t-r", name: "Old")
    trader.update_columns(updated_at: Time.current)
    def trader.update!(*)
      raise ActiveRecord::RecordInvalid.new(self)
    end

    syncer = Tarkov::Syncers::FandomNameSyncer.new(client: FakeTarkovClient.new)
    result = syncer.send(:apply_name, trader, "New Name")

    assert_not result
    assert_equal "Old", trader.reload.name
  end

  test "title_from_link rescues malformed links" do
    syncer = Tarkov::Syncers::FandomNameSyncer.new(client: FakeTarkovClient.new)

    assert_nil syncer.send(:title_from_link, "http://exa mple with spaces")
  end
end
