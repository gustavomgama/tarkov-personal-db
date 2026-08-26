require "test_helper"

class UnlockStructureTest < ActiveSupport::TestCase
  setup do
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
    @item = Item.find_by!(tid: "item-1-default")
    @supplier = Task.find_by!(tid: "task-1")
    @follower = Task.find_by!(tid: "task-2")
    @trader = Trader.find_by!(tid: "trader-1")
  end

  test "syncs task requirement edges from payload" do
    assert_equal [ @supplier ], @follower.required_tasks
    assert_equal [ @follower ], @supplier.unlocking_tasks
  end

  test "syncs trader loyalty levels with requirements" do
    levels = @trader.trader_loyalty_levels.order(:level)
    assert_equal [ 1, 2 ], levels.pluck(:level)
    assert_equal [ 0, 6 ], levels.pluck(:required_player_level)
    assert_in_delta 0.7, levels.second.required_reputation.to_f
  end

  test "finds tasks by wiki title" do
    @follower.update!(wiki_link: "https://escapefromtarkov.fandom.com/wiki/No_trader_task")

    assert_equal @follower, Task.find_by_wiki_title("No Trader Task")
    assert_equal @follower, Task.find_by_wiki_title("No Trader Task.")
    assert_nil Task.find_by_wiki_title("")
    assert_nil Task.find_by_wiki_title("Nonexistent Quest")
  end

  test "finds tasks by alternative slash-separated titles" do
    @follower.update!(name: "Shaking Up the Teller")

    assert_equal @follower, Task.find_by_wiki_title("Oil Run/Shaking Up the Teller")
  end

  test "resolves full unlock path from item through chain to root quest" do
    @follower.update!(name: "Wet Job - Part 1", min_player_level: 14)
    @supplier.update!(name: "The Guide")
    final_task = Task.create!(tid: "task-final", name: "The Cleaner",
                              wiki_link: "https://escapefromtarkov.fandom.com/wiki/The_Cleaner")
    TaskRequirement.create!(task: final_task, required_task: @follower)
    final_task = Task.find_by!(name: "The Cleaner")
    ItemUnlock.create!(item: @item, trader_name: "Peacekeeper", loyalty_level: 4,
                       task_id: final_task.id, item_name: @item.name)
    @item.item_unlocks.where.not(trader_name: "Peacekeeper").destroy_all

    entries = Tarkov::UnlockPathResolver.new(@item).resolve

    assert_equal 1, entries.size
    entry = entries.first

    assert_equal "Peacekeeper", entry.unlock.trader_name
    assert_equal final_task, entry.task
    assert_equal [ @follower, @supplier ], entry.prerequisites.map { |node| node[:task] }
    assert_equal [ 1, 2 ], entry.prerequisites.map { |node| node[:depth] }
    assert_equal [ @supplier ], entry.root_quests.map { |node| node[:task] }
    assert_equal 14, entry.required_player_level
  end

  test "resolver handles unresolvable unlocking task gracefully" do
    unlock = ItemUnlock.create!(item: @item, trader_name: "Fence", item_name: @item.name)

    entry = Tarkov::UnlockPathResolver.new(@item).resolve.first

    assert_equal unlock, entry.unlock
    assert_nil entry.task
    assert_empty entry.prerequisites
    assert_nil entry.required_player_level
  end

  test "merged_chain orders dependencies before dependents" do
    root = Task.create!(tid: "mc-root", name: "AAA Entry", min_player_level: 8)
    mid = Task.create!(tid: "mc-mid", name: "BBB Mid")
    final = Task.create!(tid: "mc-final", name: "CCC Final")
    TaskRequirement.create!(task: mid, required_task: root)
    TaskRequirement.create!(task: final, required_task: mid)
    ItemUnlock.create!(item: @item, trader_name: "Mechanic", loyalty_level: 3,
                       task_id: final.id, item_name: @item.name)
    entry = Tarkov::UnlockPathResolver.new(@item).resolve.find { |e| e.task&.id == final.id }

    names = Tarkov::UnlockPathResolver.merged_chain([ entry ]).map(&:name)

    assert_equal [ "AAA Entry", "BBB Mid", "CCC Final" ], names
  end

  test "trader purge keeps whitelist and removes their unlock rows" do
    kept = Trader.create!(tid: "keep-1", name: "Fence")
    gone = Trader.create!(tid: "gone-1", name: "Anton")
    orphan_row = ItemUnlock.create!(item: @item, trader: gone, trader_name: "Anton",
                                    loyalty_level: 2, unlock_types: [ "barter" ], item_name: @item.name)

    removed = Tarkov::Syncers::TraderPurge.new.call

    assert_operator removed, :>=, 1
    assert_not Trader.exists?(gone.id)
    assert_not ItemUnlock.exists?(orphan_row.id)
    assert Trader.exists?(kept.id)
  end
end
