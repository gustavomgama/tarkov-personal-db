require "test_helper"

class FrontEndDebugTest < ActionDispatch::IntegrationTest
  setup do
    Tarkov::Syncers::TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
    Tarkov::Syncers::ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
    Tarkov::Syncers::TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
    @item = Item.find_by!(tid: "item-1")
    @task = Task.find_by!(tid: "task-1")
  end

  test "item page renders multiple distinct route chips" do
    @item.update!(barter: true, require_unlock: true)
    ItemUnlock.create!(item: @item, trader_name: "Peacekeeper", loyalty_level: 4,
                       task: @task, unlock_types: [ "money" ], item_name: @item.name)
    ItemUnlock.create!(item: @item, trader_name: "Ref", loyalty_level: 3,
                       task: @task, unlock_types: [ "money" ], item_name: @item.name)

    get item_path(@item)

    assert_response :success
    assert_match "Ref", response.body
    assert_match "Peacekeeper", response.body
    assert_match "LL3", response.body
    assert_match "LL4", response.body
  end

  test "task page tolerates malformed wiki links on enrichment" do
    @task.update!(wiki_link: "http://exa mple")

    silence do
      Tarkov::Syncers::FandomEnrichmentSyncer.new(
        client: FakeTarkovClient.new,
        fandom_client: FakeFandomClient.new(wikitext: { "The Cleaner" => nil })
      ).call
    end
  end

  def silence(&block)
    old = Rails.logger.level
    Rails.logger.level = Logger::ERROR
    block.call
  ensure
    Rails.logger.level = old
  end
end
