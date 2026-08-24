require "test_helper"

# Full-stack frontend coverage: every page, its data shapes and edge cases,
# exercised through routing -> controller -> views.
class FrontendTest < ActionDispatch::IntegrationTest
  setup do
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call

    @prapor = Trader.find_by!(tid: "trader-1")
    @mechanic = Trader.create!(tid: "trader-empty", name: "Mechanic")
    @empty_trader = Trader.create!(tid: "trader-none", name: "Skier")
    @m80 = Item.find_by!(tid: "item-1")
    @bare = Item.create!(tid: "item-bare", name: "Bare Thing")
    @ammo = Item.create!(tid: "item-2", name: "M855 Ammo")

    # root <- mid / mid2 (branch) <- final, and the item unlocks via final.
    @root = Task.create!(tid: "task-root", name: "Wet Job - Part 1", min_player_level: 14)
    @mid = Task.create!(tid: "task-mid", name: "Wet Job - Part 6")
    @mid2 = Task.create!(tid: "task-mid2", name: "Side Branch")
    @final = Task.find_by!(tid: "task-1") # Supplier, gated by task-2 upstream
    TaskRequirement.create!(task: @mid, required_task: @root)
    TaskRequirement.create!(task: @mid2, required_task: @root)
    TaskRequirement.create!(task: @final, required_task: @mid)

    ItemUnlock.create!(item: @m80, item_name: @m80.name, trader: @prapor,
                       trader_name: "Prapor", loyalty_level: 2, task: @final,
                       unlock_types: [ "money" ], source: "dev")
    ItemUnlock.create!(item: @m80, item_name: @m80.name, trader: @mechanic,
                       trader_name: "Mechanic", loyalty_level: 3, task: @mid2,
                       unlock_types: [ "money" ], source: "dev")
    @barter_item = Item.create!(tid: "qitem-9", name: "Intel").tap { |i| i.update!(barter: true) }
    ItemUnlock.create!(item: @barter_item, item_name: "Intel", trader: @prapor,
                       trader_name: "Prapor", loyalty_level: 4,
                       unlock_types: [ "barter" ], source: "dev")
  end

  test "root serves the items index" do
    get "/"
    assert_response :success
    assert_match "Item Database", response.body
  end

  test "items index renders prices, badges and pagination" do
    get items_path
    assert_response :success
    assert_match "records", response.body
    assert_match "70 USD", response.body
    assert_match "task-gated", response.body
    assert_match "barter", response.body
  end

  test "items index search matches tokens in any order" do
    get items_path, params: { q: "m4a1 colt" }
    assert_response :success
    assert_match "Colt M4A1", response.body
  end

  test "items index shows empty-state for no matches" do
    get items_path, params: { q: "zzzznotathing" }
    assert_response :success
    assert_match "Nothing matches", response.body
  end

  test "items index filters by currency and flags" do
    get items_path, params: { currency: "USD" }
    assert_response :success
    assert_match "70 USD", response.body

    get items_path, params: { barter: "1" }
    assert_response :success
    assert_match "Intel", response.body
  end

  test "items index clamps per-page and paginates" do
    11.times { |i| Item.create!(tid: "pad-#{i}", name: "Filler #{i}") }

    get items_path, params: { per: "9999", page: "-5" }
    assert_response :success
    assert_match "15 records", response.body

    get items_path, params: { per: "10", page: "2" }
    assert_response :success
    assert_match "page 2 /", response.body
    assert_match "Prev", response.body
  end

  test "item show renders routes, tree branches and unlock markers" do
    get item_path(@m80)
    assert_response :success
    assert_match "Money —", response.body
    assert_match "Needs player level 6", response.body
    assert_match "Supplier", response.body
    assert_match "unlocks item", response.body
    assert_match "Side Branch", response.body
    assert_match "requires player level 14+", response.body
    assert_match "Compatible ammunition", response.body
  end

  test "item show handles an item with no acquisition routes" do
    get item_path(@bare)
    assert_response :success
    assert_match "No acquisition routes recorded", response.body
  end

  test "item show notes when conditions exist without a chain" do
    get item_path(@barter_item)
    assert_response :success
    assert_match "No quest chain recorded", response.body
  end

  test "unknown item renders 404" do
    get item_path(id: 0)
    assert_response :missing
  end

  test "tasks index lists tasks with level and gate counts" do
    get tasks_path
    assert_response :success
    assert_match "Supplier", response.body
    assert_match "5+</span>", response.body
    assert_match "Any trader", response.body
  end

  test "tasks index pluralizes gate counts without literal interpolation" do
    get tasks_path
    assert_response :success
    assert_no_match "item#", response.body
    assert_match %r{<span class="badge text-bg-primary">2 items</span>}, response.body
  end

  test "tasks index shows a count, not the grouped-relation size hash" do
    get tasks_path
    assert_response :success
    assert_no_match "=>", response.body
    assert_match "5 shown", response.body
  end

  test "tasks index filters by trader and name" do
    get tasks_path, params: { trader_id: @prapor.id }
    assert_response :success
    assert_match "Supplier", response.body

    get tasks_path, params: { q: "no trader" }
    assert_response :success
    assert_match "No trader task", response.body
    assert_no_match "Supplier</a>", response.body
  end

  test "task show renders badges, unlocks panel and wiki link" do
    @final.update!(kappa_required: true, lightkeeper_required: true, min_player_level: 5,
                   wiki_link: "https://escapefromtarkov.fandom.com/wiki/Supplier")
    get task_path(@final)
    assert_response :success
    assert_match "counts for Kappa", response.body
    assert_match "Lightkeeper route", response.body
    assert_match "requires player level 5+", response.body
    assert_match "Completing this task unlocks", response.body
    assert_match "money", response.body
    assert_match "Prapor", response.body
    assert_match "Wiki ↗", response.body
    assert_match "Previous:", response.body
    assert_match "▸", response.body
  end

  test "task show renders empty unlocks message" do
    get task_path(@mid)
    assert_response :success
    assert_match "No items are gated behind this task", response.body
  end

  test "unknown task renders 404" do
    get task_path(id: 0)
    assert_response :missing
  end

  test "traders index lists all traders as cards" do
    get traders_path
    assert_response :success
    assert_match "Prapor", response.body
    assert_match "Mechanic", response.body
  end

  test "trader show renders loyalty ladder, gated list and open stock" do
    get trader_path(@prapor)
    assert_response :success
    assert_match "Loyalty progression", response.body
    assert_match "LL1", response.body
    assert_match "LL2", response.body
    assert_match "Task-gated items", response.body
    assert_match "Colt M4A1</a>", response.body
    assert_match "Open stock", response.body
    assert_match "wiki/Prapor", response.body
  end

  test "trader show renders empty states when nothing recorded" do
    get trader_path(@empty_trader)
    assert_response :success
    assert_match "None recorded.", response.body
    assert_match "No open-sale items recorded.", response.body
  end

  test "unknown trader renders 404" do
    get trader_path(id: 0)
    assert_response :missing
  end
end
