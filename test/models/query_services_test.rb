require "test_helper"

class QueryServicesTest < ActiveSupport::TestCase
  setup do
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
    @item = Item.find_by!(tid: "item-1")
    @trader = Trader.find_by!(tid: "trader-1")
    @supplier = Task.find_by!(tid: "task-1")
    @follower = Task.find_by!(tid: "task-2")
  end

  test "item unlock lookup combines resolver paths with purchase routes" do
    ItemUnlock.create!(item: @item, trader: @trader, trader_name: "Prapor", loyalty_level: 2,
                       task_id: @supplier.id, unlock_types: [ "money" ], item_name: @item.name)

    result = Tarkov::ItemUnlockLookup.new(@item).call

    assert_equal @item, result[:item]
    route = result[:purchase_routes].sole
    assert_equal "Prapor", route[:trader]
    assert_equal 2, route[:loyalty_level]
    assert_equal "Supplier", route[:via_task]
  end

  test "task chain view walks prerequisites up and unlocked tasks down" do
    view = Tarkov::TaskChainView.new(@follower).call

    assert_equal @follower, view[:task]
    assert_equal [ @supplier ], view[:requires].map { |node| node[:task] }
    assert_empty view[:leads_to]

    upstream = Tarkov::TaskChainView.new(@supplier).call

    assert_empty upstream[:requires]
    assert_equal [ @follower ], upstream[:leads_to].map { |node| node[:task] }
  end
end
