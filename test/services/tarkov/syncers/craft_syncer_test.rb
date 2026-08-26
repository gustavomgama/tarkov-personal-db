require "test_helper"

module Tarkov
  module Syncers
    class CraftSyncerTest < ActiveSupport::TestCase
      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        @craft_payload = [
          { "id" => "c-1", "productItem" => { "item" => "item-1", "count" => 1 },
            "requiredItems" => [ { "item" => "item-2", "count" => 2 } ] }
        ]
      end

      test "creates craft unlock rows and flags the item craftable" do
        count = CraftSyncer.new(client: FakeTarkovClient.new(crafts: @craft_payload)).call

        assert_equal 1, count
        row = Item.find_by!(tid: "item-1-default").item_unlocks.of_type("craft").sole
        assert_equal "dev", row.source
        assert_predicate Item.find_by!(tid: "item-1-default").reload, :craft?
      end

      test "stores station, level and consumed ingredients for the route card" do
        payload = [
          { "id" => "c-9", "station" => "st-med", "level" => 3,
            "productItem" => { "item" => "item-1-default", "count" => 1 },
            "requiredItems" => [
              { "item" => "item-2", "count" => 4 },
              { "item" => "item-5", "count" => 1, "attributes" => { "tool" => true } }
            ] }
        ]
        client = FakeTarkovClient.new(
          crafts: payload,
          hideout: { "st-med" => { "id" => "st-med", "name" => "hideout_area_3_name",
                                   "normalizedName" => "medstation" } },
          hideout_en: { "hideout_area_3_name" => "Medstation" }
        )
        CraftSyncer.new(client: client).call

        row = Item.find_by!(tid: "item-1-default").item_unlocks.of_type("craft").sole
        assert_equal "Medstation", row.station
        assert_equal 3, row.station_level
        assert_equal [ "item-2" ], row.required_items.map { |i| i["tid"] } # tools excluded
      end

      test "is idempotent and cleans up stale craft rows" do
        client = FakeTarkovClient.new(crafts: @craft_payload)
        CraftSyncer.new(client: client).call
        orphan = Item.create!(tid: "item-old", name: "Old Craft")
        ItemUnlock.create!(item: orphan, item_name: "Old Craft",
                           unlock_types: [ "craft" ], source: "dev")

        CraftSyncer.new(client: client).call

        assert_equal 1, ItemUnlock.of_type("craft").count
        assert_nil ItemUnlock.find_by(item_id: orphan.id)
      end

      test "skips crafts whose product is unknown or missing" do
        payload = @craft_payload + [ { "id" => "c-2", "productItem" => { "item" => "ghost" } }, { "id" => "c-3" } ]

        assert_equal 1, CraftSyncer.new(client: FakeTarkovClient.new(crafts: payload)).call
      end

      test "survives invalid updates" do
        original = Item.instance_method(:update!)
        Item.define_method(:update!) { |*| raise ActiveRecord::RecordInvalid.new(self) }

        assert_equal 0, CraftSyncer.new(client: FakeTarkovClient.new(crafts: @craft_payload)).call
      ensure
        Item.define_method(:update!, original)
      end
    end
  end
end
