require "test_helper"

module Tarkov
  module Syncers
    class TraderSyncerTest < ActiveSupport::TestCase
      test "creates traders with parsed reset time" do
        count = TraderSyncer.new(client: fake_client).call

        assert_equal 1, count
        trader = Trader.find_by!(tid: "trader-1")
        assert_equal "Prapor", trader.name
        assert_equal Time.zone.parse("2026-08-21T08:40:23.000Z"), trader.reset_time
      end

      private

      def fake_client
        FakeTarkovClient.new(traders: trader_payload)
      end
    end
  end
end
