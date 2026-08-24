require "test_helper"

class TradersControllerTest < ActionDispatch::IntegrationTest
  setup do
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    trader = Trader.first
    item = Item.create!(tid: "i-x", name: "Gated Thing")
    ItemUnlock.create!(item: item, trader: trader, trader_name: trader.name,
                       loyalty_level: 1, task: Task.create!(tid: "t-x", name: "Gate Task"),
                       unlock_types: [ "money" ], item_name: item.name)
  end

  test "index lists traders" do
    get traders_path
    assert_response :success
    assert_match "Prapor", response.body
  end

  test "show renders loyalty ladder and gated items" do
    trader = Trader.first
    get trader_path(trader)
    assert_response :success
    assert_match "Loyalty progression", response.body
    assert_match "Gated Thing", response.body
  end
end
