require "test_helper"

class FrontEndDebugTest < ActionDispatch::IntegrationTest
  setup do
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
    @item = Item.find_by!(tid: "item-1-default")
    @task = Task.find_by!(tid: "task-1")
  end

  test "item page renders one offer line per trader, not a merged phrase" do
    ItemUnlock.create!(item: @item, trader_name: "Peacekeeper", loyalty_level: 4,
                       task: @task, unlock_types: [ "money" ], item_name: @item.name)
    ItemUnlock.create!(item: @item, trader_name: "Ref", loyalty_level: 3,
                       task: @task, unlock_types: [ "money" ], item_name: @item.name)

    get item_path(@item)

    assert_response :success
    flat = response.body.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ")
    assert_match(/BUY Buy from R? ?Ref LL3/, flat)
    assert_match(/BUY Buy from P? ?Peacekeeper LL4/, flat)
    assert_no_match "or Buy from", flat
  end
end
