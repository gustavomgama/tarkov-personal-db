require "test_helper"

module Tarkov
  class SyncerTest < ActiveSupport::TestCase
    test "runs all sync steps in order" do
      client = FakeTarkovClient.new(
        items: item_payload,
        traders: trader_payload,
        tasks: tasks_payload,
        barters: barter_payload,
        hideout: hideout_payload
      )
      Item.create!(tid: "item-2", name: "Dollars")

      results = Syncer.new(client: client, logger: Logger.new(nil), fandom_client: FakeFandomClient.new).call

      assert_equal %w[items traders tasks barters hideout], client.requested.uniq
      assert_equal 1, results[:items]
      assert_equal 1, results[:traders]
      assert_equal 2, results[:tasks]
      assert_equal 1, results[:barters]
      assert_equal 2, results[:hideout]
      assert_kind_of Hash, results[:fandom_names]
    end
  end
end
