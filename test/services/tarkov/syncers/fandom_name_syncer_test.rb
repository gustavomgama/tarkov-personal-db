require "test_helper"

module Tarkov
  module Syncers
    class FandomNameSyncerTest < ActiveSupport::TestCase
      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
        TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
        @item = Item.find_by!(tid: "item-1")
        @item.update!(wiki_link: "https://escapefromtarkov.fandom.com/wiki/Colt_M4A1_5.56x45_assault_rifle")
        @task = Task.find_by!(tid: "task-1")
        @task.update!(wiki_link: "https://escapefromtarkov.fandom.com/wiki/Supplier")
      end

      test "overwrites names from resolved wiki titles" do
        fandom = FakeFandomClient.new(
          pages: {
            "Colt M4A1 5.56x45 assault rifle" => "Colt M4A1 5.56x45 assault rifle",
            "Supplier" => nil
          },
          category_members: { "Category:Traders" => [ "Prapor" ] }
        )
        HideoutStation.create!(tid: "station-1", name: "x", normalized_name: "water-collector")

        results = FandomNameSyncer.new(client: fake_dev_client, fandom_client: fandom).call

        assert_equal 1, results[:items]
        assert_equal "Colt M4A1 5.56x45 assault rifle", @item.reload.name

        assert_equal 0, results[:tasks]
        assert_equal "Supplier", @task.reload.name

        assert_equal 1, results[:traders]
        assert_equal "Prapor", Trader.find_by!(tid: "trader-1").name

        assert_equal 1, results[:stations]
        assert_equal "Water Collector", HideoutStation.find_by!(tid: "station-1").name
      end

      private

      def fake_dev_client
        FakeTarkovClient.new
      end
    end
  end
end
