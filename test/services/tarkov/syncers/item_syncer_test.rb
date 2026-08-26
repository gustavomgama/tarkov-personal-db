require "test_helper"

module Tarkov
  module Syncers
    class ItemSyncerTest < ActiveSupport::TestCase
      test "creates items with slim attribute set" do
        count = ItemSyncer.new(client: fake_client).call

        assert_equal 6, count
        item = Item.find_by!(tid: "item-1-default")
        assert_equal "Colt M4A1", item.name
        assert_equal "https://assets.tarkov.dev/item-1-512.webp", item.icon_link
        assert_equal "https://assets.tarkov.dev/item-1-8x.webp", item.image_link
        assert_equal [ "gun" ], item.categories
        assert_equal 70.0, item.price
        refute_includes item.price.to_s, "e"
        assert_predicate item, :gun?
        assert_equal "Caliber556x45NATO", item.caliber
        assert_equal [ "item-2" ], item.allowed_ammo
        assert_equal "USD", item.currency
        assert_not item.barter?
        assert_not item.craft?
        assert_not item.require_unlock?
      end

      test "populates penetration_power for ammo items" do
        ItemSyncer.new(client: fake_client).call
        ammo = Item.find_by!(tid: "ammo-m855")
        assert_equal 37, ammo.penetration_power
        assert_equal 42, ammo.damage
        assert_predicate ammo, :ammo?
      end

      test "populates armor_class for armor items" do
        ItemSyncer.new(client: fake_client).call
        armor = Item.find_by!(tid: "armor-class5")
        assert_equal 5, armor.armor_class
      end

      test "is idempotent on re-run" do
        syncer = ItemSyncer.new(client: fake_client)
        syncer.call
        assert_no_difference("Item.count") { syncer.call }
      end

      private

      def fake_client
        FakeTarkovClient.new(items: item_payload)
      end
    end
  end
end
