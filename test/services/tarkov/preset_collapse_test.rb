require "test_helper"

module Tarkov
  class PresetCollapseTest < ActiveSupport::TestCase
    setup do
      @payload = [
        { "id" => "base-1", "normalizedName" => "ak-74n", "name" => "AK-74N", "types" => [ "gun" ],
          "properties" => { "caliber" => "Caliber545x39", "allowedAmmo" => [ "ammo-1" ] } },
        { "id" => "default-1", "normalizedName" => "ak-74n-default", "name" => "AK-74N", "types" => [ "preset" ] },
        { "id" => "build-1", "normalizedName" => "ak-74n-magpul-build", "name" => "AK-74N Magpul", "types" => [ "preset" ] },
        { "id" => "base-2", "normalizedName" => "m4a1", "name" => "M4A1", "types" => [ "gun" ],
          "properties" => { "caliber" => "Caliber556x45" } },
        { "id" => "stray-1", "normalizedName" => "totally-unrelated-preset", "name" => "Stray", "types" => [ "preset" ] }
      ]
      Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: { "items" => @payload.index_by { |p| p["id"] } })).call
    end

    test "collapses each weapon family onto its default preset" do
      assert Item.exists?(tid: "default-1")
      refute Item.exists?(tid: "base-1")
      refute Item.exists?(tid: "build-1")

      canonical = Item.find_by!(tid: "default-1")
      assert_equal "Caliber545x39", canonical.caliber            # merged from base
      assert_equal [ "gun" ], canonical.categories                # derived from base types
      assert_equal "https://tarkov.dev/item/ak-74n-default", "https://tarkov.dev/item/#{canonical.slug}"
    end

    test "gun families without a -default keep the base gun as the standard variant" do
      # M4A1 upstream ships no preset at all: the base gun IS the standard.
      assert Item.exists?(tid: "base-2")
      assert_equal "base-2", ItemAlias.resolve("base-2")
    end

    test "defaultless standalone guns keep their unlocks and images" do
      pistol = Item.create!(tid: "pistol", name: "SP-81", slug: "zid-sp-81-signal-pistol")
      ItemUnlock.create!(item: pistol, item_name: pistol.name, trader_name: "Mechanic",
                         unlock_types: [ "money" ])
      image = Rails.root.join("public/images/items/pistol-icon.webp")
      FileUtils.mkdir_p(image.dirname)
      File.write(image, "")

      collapse = PresetCollapse.new(
        [ { "id" => "pistol", "normalizedName" => "zid-sp-81-signal-pistol", "types" => [ "gun" ] } ]
      )
      collapse.remap_records!

      assert Item.exists?(pistol.id)
      assert File.exist?(image)
    ensure
      FileUtils.rm_f(image) if defined?(image) && image && File.exist?(image)
    end

    test "presets from an unknown family stay standalone items" do
      assert Item.exists?(tid: "stray-1")
    end

    test "sibling color-defaults fold into the shortest default of the family" do
      attrs = [
        { "id" => "hk-base", "normalizedName" => "hk-416a5", "types" => [ "gun" ], "wikiLink" => "https://w/HK416" },
        { "id" => "hk-def", "normalizedName" => "hk-416a5-default", "types" => [ "preset" ], "wikiLink" => "https://w/HK416" },
        { "id" => "hk-ral", "normalizedName" => "hk-416a5-ral8000-default", "types" => [ "preset" ], "wikiLink" => "https://w/HK416" }
      ]
      collapse = PresetCollapse.new(attrs)

      assert_equal "hk-def", collapse.resolve("hk-ral")
      refute collapse.drop?("hk-def")
    end

    test "unrelated items sharing a bad wiki link are not folded together" do
      attrs = [
        { "id" => "carrier", "normalizedName" => "tac-kek-jaypc-carrier", "types" => [ "rig" ], "wikiLink" => "https://w/SHARED" },
        { "id" => "rifle", "normalizedName" => "fn-scar-h-x17-rifle", "types" => [ "gun" ], "wikiLink" => "https://w/SHARED" }
      ]
      collapse = PresetCollapse.new(attrs)

      refute collapse.drop?("carrier")
      refute collapse.drop?("rifle")
      # Unrelated items must never fold into each other despite the shared link.
      assert_equal "rifle", collapse.resolve("rifle")
      assert_equal "carrier", collapse.resolve("carrier")
    end

    test "colorway variants fold into the bare or shortest member of their wiki family" do
      attrs = [
        { "id" => "mag", "normalizedName" => "ak-pmag-30", "types" => [ "magazine" ], "wikiLink" => "https://w/PMAG" },
        { "id" => "mag-plum", "normalizedName" => "ak-pmag-30-plum", "types" => [ "magazine" ], "wikiLink" => "https://w/PMAG" },
        { "id" => "palm-black", "normalizedName" => "us-palm-ak30-black", "wikiLink" => "https://w/AK30" },
        { "id" => "palm-fde", "normalizedName" => "us-palm-ak30-fde", "wikiLink" => "https://w/AK30" }
      ]
      collapse = PresetCollapse.new(attrs)

      assert_equal "mag", collapse.resolve("mag-plum")
      assert collapse.drop?("mag-plum"), "bare form wins"
      refute collapse.drop?("palm-fde"), "shortest slug represents a bare-less family"
      assert collapse.drop?("palm-black")
      assert_equal "palm-fde", collapse.resolve("palm-black")
    end

    test "with no price signal the trader-sold variant becomes the standard" do
      attrs = [
        { "id" => "scar-bare", "normalizedName" => "fn-scar-h-762x51-assault-rifle", "types" => [ "gun" ], "wikiLink" => "https://w/SCARH" },
        { "id" => "scar-flir", "normalizedName" => "fn-scar-h-762x51-assault-rifle-flir-rs-32", "types" => [ "preset" ], "wikiLink" => "https://w/SCARH" },
        { "id" => "scar-lb", "normalizedName" => "fn-scar-h-762x51-assault-rifle-lb",
          "types" => [ "preset" ], "buyFromTrader" => [ { "trader" => "t1", "priceRUB" => 100 } ], "wikiLink" => "https://w/SCARH" },
        { "id" => "scar-uh1", "normalizedName" => "fn-scar-h-762x51-assault-rifle-uh-1", "types" => [ "preset" ], "wikiLink" => "https://w/SCARH" }
      ]
      collapse = PresetCollapse.new(attrs)

      assert_equal "scar-lb", collapse.resolve("scar-bare")
      assert collapse.drop?("scar-bare")
    end

    test "bare official-name guns fold onto the standard variant" do
      attrs = [
        { "id" => "pistol", "normalizedName" => "zid-sp-81-signal-pistol", "types" => [ "gun" ], "wikiLink" => "https://w/SP81" },
        { "id" => "m4a1-bare", "normalizedName" => "colt-m4a1-556x45-assault-rifle", "types" => [ "gun" ],
          "avg24hPrice" => 91410, "wikiLink" => "https://w/M4A1" },
        { "id" => "m4a1-sai", "normalizedName" => "colt-m4a1-556x45-assault-rifle-sai",
          "types" => [ "preset" ], "wikiLink" => "https://w/M4A1" },
        { "id" => "m4a1-carbine", "normalizedName" => "colt-m4a1-556x45-assault-rifle-carbine",
          "types" => [ "preset" ], "avg24hPrice" => 91410, "wikiLink" => "https://w/M4A1" }
      ]
      collapse = PresetCollapse.new(attrs)

      refute collapse.drop?("pistol"), "standalone gun with no variants stays"
      assert collapse.drop?("m4a1-bare"), "bare official name is never kept"
      assert_equal "m4a1-carbine", collapse.resolve("m4a1-bare")
    end

    test "family keeper prefers the plain -default over other variants" do
      attrs = [
        { "id" => "sr3m-bare", "normalizedName" => "sr-3m-9x39-compact-assault-rifle", "types" => [ "gun" ],
          "properties" => { "caliber" => "Caliber9x39" }, "wikiLink" => "https://w/SR3M" },
        { "id" => "sr3m-carbine", "normalizedName" => "sr-3m-9x39-compact-assault-rifle-carbine",
          "types" => [ "preset" ], "wikiLink" => "https://w/SR3M" },
        { "id" => "sr3m-default", "normalizedName" => "sr-3m-9x39-compact-assault-rifle-default",
          "types" => [ "preset" ], "wikiLink" => "https://w/SR3M" }
      ]
      collapse = PresetCollapse.new(attrs)

      assert_equal "sr3m-default", collapse.resolve("sr3m-bare")
      assert_equal "sr3m-default", collapse.resolve("sr3m-carbine")
    end

    test "stale aliases are cleaned by the AliasHygiene step" do
      ItemAlias.create!(tid: "old-1", canonical_tid: "vanished-tid")
      holder = Item.find_by!(tid: "default-1")
      ItemAlias.create!(tid: "old-2", canonical_tid: "build-1") # build-1 folds to default-1

      Tarkov::Syncers::AliasHygiene.new(client: FakeTarkovClient.new).call

      assert_equal "default-1", ItemAlias.resolve("old-2")
      assert_nil ItemAlias.find_by(tid: "old-1")
    end

    test "records aliases so future payloads resolve to the canonical item" do
      assert_equal "default-1", ItemAlias.resolve("base-1")
      assert_equal "default-1", ItemAlias.resolve("build-1")
      assert_equal "base-2", ItemAlias.resolve("base-2")

      assert_equal Item.find_by!(tid: "default-1"), Item.find_canonical("base-1")
    end

    test "repoints unlocks and barter ingredients, then is idempotent" do
      holder = Item.find_by!(tid: "default-1")
      # Simulate rows written before collapse: unlock + ingredient on dropped tids.
      stale_build = Item.create!(tid: "build-1", name: "AK-74N Magpul")
      unlock = ItemUnlock.create!(item: stale_build, item_name: stale_build.name,
                                  trader_name: "Mechanic", unlock_types: [ "money" ])
      recipe = ItemUnlock.create!(item: holder, item_name: holder.name, trader_name: "Prapor",
                                  unlock_types: [ "barter" ],
                                  required_items: [ { "tid" => "build-1", "name" => stale_build.name,
                                                      "icon_link" => "", "count" => 2 } ])

      collapse = PresetCollapse.new(@payload)
      collapse.remap_records!
      collapse.remap_records! # second run must be a no-op

      assert_not Item.exists?(stale_build.id)
      assert_equal holder.id, unlock.reload.item_id
      assert_equal "default-1", recipe.reload.required_items.first["tid"]
    end

    test "rewrites aliases that point at something dropped in a later run" do
      ItemAlias.create!(tid: "old-ref", canonical_tid: "build-1")

      PresetCollapse.new(@payload).remap_records!

      assert_equal "default-1", ItemAlias.resolve("old-ref")
    end

    test "dedupes identical unlock rows created by repointing" do
      trader = Trader.create!(tid: "tr-2", name: "Skier")
      holder = Item.find_by!(tid: "default-1")
      dropped = Item.create!(tid: "build-1", name: "AK-74N Magpul")
      2.times do |i|
        ItemUnlock.create!(item: i.zero? ? dropped : holder, item_name: "x",
                           trader_name: "Skier", loyalty_level: 3, unlock_types: [ "money" ])
      end

      PresetCollapse.new(@payload).remap_records!

      assert_equal 1, holder.item_unlocks.where(trader_name: "Skier").count
      assert_equal trader.name, holder.item_unlocks.first.trader_name
    end
  end
end
