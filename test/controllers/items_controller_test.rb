require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sync_base_data
    @item = Item.find_by!(tid: "item-1")
  end

  test "index lists items with price and badges" do
    get items_path
    assert_response :success
    assert_match "Item Database", response.body
  end

  test "index search matches tokens in any order" do
    get items_path, params: { q: "colt m4a1" }
    assert_response :success
    assert_match "Colt M4A1", response.body
  end

  test "index filters by currency and flags" do
    Item.find_by!(tid: "item-1").update!(currency: "USD", barter: true)
    get items_path, params: { currency: "USD", barter: "1" }
    assert_response :success
    assert_match "Colt M4A1", response.body
  end

  test "index paginates" do
    get items_path, params: { per: 10, page: 2 }
    assert_response :success
    assert_match "page 2 /", response.body
  end

  test "show renders routes and compatible ammo for a gun" do
    get item_path(@item)
    assert_response :success
    assert_match "Supplier", response.body
    assert_match "Compatible ammunition", response.body
    assert_match "Dollars", response.body
  end

  test "show renders compatible guns for an ammo item" do
    Item.find_by!(tid: "item-2").update!(ammo: true, caliber: "Caliber556x45NATO")
    Item.find_by!(tid: "gun-77").update!(caliber: "Caliber556x45NATO")

    get item_path(Item.find_by!(tid: "item-2"))
    assert_response :success
    assert_match "Compatible guns", response.body
    assert_match "SA-58 Rifle", response.body
  end

  private

  def sync_base_data
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
    Item.create!(tid: "qitem-9", name: "Intel")
    Item.create!(tid: "item-2", name: "Dollars")
    12.times { |i| Item.create!(tid: "pad-#{i}", name: "Filler Item #{i}") }
    Item.create!(tid: "gun-77", name: "SA-58 Rifle", gun: true,
                 allowed_ammo: [ Item.find_by!(tid: "item-1").tid ])
  end
end
