require "test_helper"

class CraftsAndUnlockTaskTest < ActiveSupport::TestCase
  setup do
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
    Tarkov::Syncers::HideoutSyncer.new(client: FakeTarkovClient.new(hideout: hideout_payload)).call
    @item_2 = Item.create!(tid: "item-2", name: "Dollars")
  end

  test "records barter unlock task on item unlocks" do
    Tarkov::Syncers::BarterSyncer.new(client: FakeTarkovClient.new(barters: barter_payload)).call

    offer = Item.find_by!(tid: "qitem-9").item_unlocks.of_type("barter").sole
    assert_equal Task.find_by!(tid: "task-1"), offer.task
  end

  test "syncs hideout crafts with required and reward items" do
    count = Tarkov::Syncers::HideoutCraftSyncer.new(
      client: FakeTarkovClient.new(crafts: crafts_payload)
    ).call

    assert_equal 1, count
    craft = HideoutCraft.find_by!(tid: "craft-1")
    assert_equal HideoutStation.find_by!(tid: "station-2"), craft.hideout_station
    assert_equal 3600, craft.duration
    assert_predicate Item.find_by!(tid: "item-2").reload, :craft?

    required = craft.craft_items.find_by!(kind: "required")
    assert_equal "item-1", required.item.tid
    assert_equal 2, required.count

    reward = craft.craft_items.find_by!(kind: "reward")
    assert_equal "item-2", reward.item.tid
    assert_equal 1, reward.count
  end

  test "removes crafts no longer present in payload" do
    syncer = ->(payload) { Tarkov::Syncers::HideoutCraftSyncer.new(client: FakeTarkovClient.new(crafts: payload)).call }
    syncer.call(crafts_payload)

    assert_difference("HideoutCraft.count", -1) do
      syncer.call([])
    end
    assert_equal 0, CraftItem.count
  end
end
