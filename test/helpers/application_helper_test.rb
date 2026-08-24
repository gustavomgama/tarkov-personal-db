require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "tk_money formats whole prices" do
    item = Item.new(price: 6500, currency: "RUB")

    assert_equal "6,500 RUB", tk_money(item)
    assert_nil tk_money(Item.new)
  end


  test "tk_condition_text renders money route with loyalty cost" do
    text = tk_condition_text(trader: "Peacekeeper", types: [ "money" ], loyalty: 4,
                             loyalty_cost: Struct.new(:required_player_level, :required_reputation).new(36, 6.0))

    assert_equal "Buy · Peacekeeper · LL4 (level 36, rep 6.0)", text
  end

  test "tk_condition_text renders craft without trader and loyalty fallback" do
    assert_equal "Craft", tk_condition_text(types: [ "craft" ], loyalty: nil, loyalty_cost: nil)

    assert_equal "Barter · Skier · LL3",
                 tk_condition_text(trader: "Skier", types: [ "barter" ], loyalty: 3, loyalty_cost: nil)
  end
end
