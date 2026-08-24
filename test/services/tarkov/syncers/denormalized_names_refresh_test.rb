require "test_helper"

class DenormalizedNamesRefreshTest < ActiveSupport::TestCase
  test "syncs item_name and trader_name to current records" do
    trader = Trader.create!(tid: "t1", name: "Old Name")
    item = Item.create!(tid: "i1", name: "New Item Name")
    row = ItemUnlock.create!(item: item, trader: trader, trader_name: "6617bee Nickname",
                             loyalty_level: 3, unlock_types: [ "barter" ], item_name: "Stale Item")

    refreshed = Tarkov::Syncers::DenormalizedNamesRefresh.new.call

    assert_operator refreshed, :>=, 1
    assert_equal "New Item Name", row.reload.item_name
    assert_equal "Old Name", row.trader_name
  end

  test "keeps trader_name for rows without a linked trader" do
    item = Item.create!(tid: "i2", name: "Thing")
    row = ItemUnlock.create!(item: item, trader_name: "Ghost Trader",
                             unlock_types: [ "craft" ], item_name: "Thing")

    Tarkov::Syncers::DenormalizedNamesRefresh.new.call

    assert_equal "Ghost Trader", row.reload.trader_name
  end
end
