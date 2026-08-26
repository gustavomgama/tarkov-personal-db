require "test_helper"

class CategoryDeriverTest < ActiveSupport::TestCase
  test "secure containers land in containers despite upstream noFlea-only types" do
    deriver = Tarkov::CategoryDeriver.new({})
    categories = deriver.derive(
      { "normalizedName" => "secure-container-gamma", "types" => [ "noFlea" ] }
    )

    assert_includes categories, "containers"
    refute_includes categories, "others"
  end

  test "meds and injectors land in medical" do
    deriver = Tarkov::CategoryDeriver.new({})

    assert_includes deriver.derive({ "normalizedName" => "salewa", "types" => %w[meds] }), "medical"
    assert_includes deriver.derive({ "normalizedName" => "propital", "types" => %w[injectors] }), "medical"
  end

  test "throwable grenades land in grenades while launcher ammo stays ammo" do
    deriver = Tarkov::CategoryDeriver.new({})

    assert_includes deriver.derive({ "normalizedName" => "rgd-5", "types" => %w[grenade] }), "grenades"
    assert_includes deriver.derive({ "normalizedName" => "m433", "types" => %w[ammo] }), "ammo"
    refute_includes deriver.derive({ "normalizedName" => "m433", "types" => %w[ammo] }), "grenades"
  end

  test "plain items without recognized types stay others" do
    deriver = Tarkov::CategoryDeriver.new({})

    assert_equal [ "others" ], deriver.derive({ "normalizedName" => "clock", "types" => [ "noFlea" ] })
  end
end
