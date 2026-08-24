require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
  end

  test "index lists tasks and filters" do
    get tasks_path
    assert_response :success
    get tasks_path, params: { q: "supplier" }
    assert_response :success
    assert_match "Supplier", response.body
  end

  test "show renders unlock panel and chain nav" do
    task = Task.find_by!(tid: "task-1")
    get task_path(task)
    assert_response :success
    assert_match "Completing this task unlocks", response.body
  end
end
