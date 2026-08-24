require "test_helper"

module Tarkov
  class CategoryDeriverTest < ActiveSupport::TestCase
    setup do
      @by_name = {
        "npp-klass-korund-vm-body-armor-black" => { "types" => %w[armor wearable], "normalizedName" => "npp-klass-korund-vm-body-armor-black" },
        "6b45-armored-rig-general-purpose-emr" => { "types" => %w[rig armor wearable], "normalizedName" => "6b45-armored-rig-general-purpose-emr" },
        "blackrock-chest-rig-gray" => { "types" => %w[rig wearable], "normalizedName" => "blackrock-chest-rig-gray" },
        "sig-mpx-9x19-submachine-gun" => { "types" => %w[gun], "normalizedName" => "sig-mpx-9x19-submachine-gun" },
        "toolbox" => { "types" => %w[container], "normalizedName" => "toolbox" },
        "glasses" => { "types" => %w[wearable glasses], "normalizedName" => "glasses" },
        "salve" => { "types" => %w[meds], "normalizedName" => "salve" }
      }
      @deriver = CategoryDeriver.new(@by_name)
    end

    test "derives canonical categories from upstream types" do
      assert_equal [ "ammo" ], @deriver.derive({ "types" => %w[ammo noFlea] })
      assert_equal [ "helmet", "wearable_parts" ].first, @deriver.derive({ "types" => %w[helmet wearable] }).first
      assert_equal [ "backpack", "wearable_parts" ].first, @deriver.derive({ "types" => %w[backpack wearable] }).first
      assert_equal [ "containers" ], @deriver.derive({ "types" => %w[container] })
    end

    test "armor and rigs split, armored rig detected by name" do
      assert_equal [ "armor" ], @deriver.derive(@by_name["npp-klass-korund-vm-body-armor-black"])
      assert_equal %w[armor armored\ rig], @deriver.derive(@by_name["6b45-armored-rig-general-purpose-emr"])
      assert_equal [ "rig" ], @deriver.derive(@by_name["blackrock-chest-rig-gray"])
    end

    test "presets inherit the base item's categories via name prefix" do
      preset = { "types" => %w[preset noFlea],
                 "normalizedName" => "sig-mpx-9x19-submachine-gun-silenced" }

      assert_equal [ "gun" ], @deriver.derive(preset)
    end

    test "unmatched items fall back to others" do
      assert_equal [ "others" ], @deriver.derive({ "types" => %w[keys] })
      assert_equal [ "others" ], @deriver.derive({ "types" => %w[poster] })
    end

    test "unresolvable presets keep their own sparse types" do
      assert_equal [ "others" ], @deriver.derive({ "types" => %w[preset noFlea], "normalizedName" => "unknown-gun-totally-new" })
    end

    test "headsets map to headset_earpiece" do
      assert_equal [ "headset_earpiece" ], @deriver.derive({ "types" => %w[headphones] })
    end
  end
end
