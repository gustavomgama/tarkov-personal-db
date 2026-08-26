require "test_helper"

module Tarkov
  class ItemAcquisitionViewTest < ActiveSupport::TestCase
    setup do
      Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    end

    test "gun exposes compatible ammunition" do
      ammo = Item.create!(tid: "item-2", name: "Some Ammo", categories: [ "ammo" ])
      gun = Item.find_by!(tid: "item-1-default")

      groups = ItemAcquisitionView.new(gun).compatibilities

      assert_equal "Compatible ammunition", groups.first[:label]
      assert_includes groups.first[:items].map(&:name), ammo.name
    end

    test "ammo lists the guns that use it" do
      gun = Item.find_by!(tid: "item-1-default")
      ammo = Item.create!(tid: "ammo-9", name: "M855", ammo: true, categories: [ "ammo" ])
      gun.update!(allowed_ammo: [ "ammo-9" ])

      groups = ItemAcquisitionView.new(ammo).compatibilities

      used = groups.find { |g| g[:label] == "Used in guns" }
      assert_not_nil used
      assert_includes used[:items].map(&:name), gun.name
    end

    test "plate item lists armor it fits and armor lists its plates" do
      plate = Item.find_by!(tid: "item-3")
      armor = Item.create!(tid: "armor-1", name: "Korund Body Armor",
                           categories: %w[armor wearable_parts],
                           compat: { "plates" => [ "item-3" ] })

      from_plate = ItemAcquisitionView.new(plate).compatibilities
      fits = from_plate.find { |g| g[:label] == "Fits into armor / armored rigs" }
      assert_not_nil fits
      assert_equal [ armor.id ], fits[:items].map(&:id)

      from_armor = ItemAcquisitionView.new(armor).compatibilities
      accepts = from_armor.find { |g| g[:label] == "Accepts ballistic plates" }
      assert_not_nil accepts
      assert_equal [ plate.id ], accepts[:items].map(&:id)
    end

    test "headset reports blocking helmets" do
      headset = Item.find_by!(tid: "item-4")

      groups = ItemAcquisitionView.new(headset).compatibilities

      blockers = groups.find { |g| g[:label] == "Does NOT fit these helmets" }
      assert_not_nil blockers
      assert_equal [ "Ratnik Helmet" ], blockers[:items].map(&:name)
    end

    test "headset without blockers gets a fits-everywhere note" do
      headset = Item.find_by!(tid: "item-4").tap { |i| i.update!(compat: { "kind" => "headset" }) }
      Item.find_by!(tid: "item-5").update!(compat: {})

      groups = ItemAcquisitionView.new(headset).compatibilities

      note = groups.find { |g| g[:label] == "Helmet fit" }
      assert_not_nil note
      assert_match(/every helmet/, note[:note])
    end

    test "plain items get no compatibility section" do
      plain = Item.create!(tid: "plain-1", name: "Bare Thing")

      assert_empty ItemAcquisitionView.new(plain.reload).compatibilities
    end
  end
end
