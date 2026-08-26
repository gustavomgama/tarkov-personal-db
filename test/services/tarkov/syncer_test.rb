require "test_helper"

module Tarkov
  class SyncerTest < ActiveSupport::TestCase
    test "runs all sync steps in order" do
      client = FakeTarkovClient.new(
        items: item_payload,
        traders: trader_payload,
        tasks: tasks_payload,
        barters: barter_payload
      )
      Item.create!(tid: "item-2", name: "Dollars")
      Item.create!(tid: "qitem-9", name: "Intel")

      results = Syncer.new(client: client, logger: Logger.new(nil), fandom_client: FakeFandomClient.new).call

      assert_equal %w[items traders tasks barters crafts], client.requested.uniq
      assert_equal 6, results[:items]
      assert_equal 1, results[:traders]
      assert_equal 2, results[:tasks]
      assert_equal 2, results[:barters]
      assert_kind_of Integer, results[:task_chains]
      assert_kind_of Integer, results[:crafts]
      assert_kind_of Integer, results[:trader_purge]
      assert_kind_of Integer, results[:junk_purge]
      assert_kind_of Integer, results[:refresh_names]
    end

    test "resolves placeholder names from localizations" do
      client = FakeTarkovClient.new(
        items: item_payload,
        tasks: tasks_payload,
        localizations: {
          items: { "item-1-default Name" => "Colt M4A1 5.56x45 assault rifle" },
          tasks: { "task-1 name" => "First in Line" }
        }
      )

      Syncer.new(client: client, logger: Logger.new(nil)).call

      assert_equal "Colt M4A1 5.56x45 assault rifle", Item.find_by!(tid: "item-1-default").name
      assert_equal "First in Line", Task.find_by!(tid: "task-1").name
    end
  end
end
