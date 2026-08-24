require "test_helper"

class UnlockPathResolverTest < ActiveSupport::TestCase
  test "walks wiki-fallback prerequisites when dev edges are absent" do
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call

    gate = Task.find_by!(tid: "task-1")
    root = Task.create!(tid: "task-0", name: "Prelude", min_player_level: 2)
    gate.update!(previous_task_id: root.id)

    entries = Tarkov::UnlockPathResolver.new(Item.find_by!(tid: "item-1")).resolve

    names = entries.flat_map { |entry| entry.prerequisites.map { |node| node[:task].name } }
    assert_includes names, "Prelude"
  end
end
