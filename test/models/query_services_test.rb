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

  test "item unlock lookup combines resolver paths with trader offers" do
    ItemUnlock.create!(item: @item, trader_title: "Prapor", loyalty_level: 2,
                       unlocking_task_title: "Supplier")
    TraderItem.create!(trader: @trader, item: @item, min_trader_level: 2, barter: true)
    @follower.update!(name: "Wet Job - Part 1", wiki_link: "https://escapefromtarkov.fandom.com/wiki/Wet_Job_-_Part_1")

    result = Tarkov::ItemUnlockLookup.new(@item).call

    assert_equal @item, result[:item]
    assert_equal 1, result[:unlock_paths].size
    assert_equal({ trader: "Prapor", min_trader_level: 2, kind: "barter" }, result[:offers].sole)
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
