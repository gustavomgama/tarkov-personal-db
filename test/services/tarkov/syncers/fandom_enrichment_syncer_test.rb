require "test_helper"

module Tarkov
  module Syncers
    class FandomEnrichmentSyncerTest < ActiveSupport::TestCase
      M80_WIKITEXT = <<~WIKI.freeze
        {{Infobox ammo
        |trader             =[[Ref]] LL3<br/>[[Peacekeeper]] LL4, after completing his task [[The Cleaner]]
        |node               =58dd3ad986f77403051cba8f
        }}

        '''{{PAGENAME}}''' is a [[7.62x51mm NATO|cartridge]].
      WIKI

      QUEST_WIKITEXT = <<~WIKI.freeze
        {{Infobox quest
        |given by     =[[Peacekeeper]]
        |previous     =[[Wet Job - Part 1]]
        }}

        '''{{PAGENAME}}''' is a [[Quests|Quest]].
      WIKI

      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
        TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
        @item = Item.find_by!(tid: "item-1")
        @item.update!(wiki_link: "https://escapefromtarkov.fandom.com/wiki/7.62x51mm_M80")
        @task = Task.find_by!(tid: "task-1")
        @task.update!(name: "The Cleaner", wiki_link: "https://escapefromtarkov.fandom.com/wiki/The_Cleaner")
        @previous = Task.find_by!(tid: "task-2").tap do |t|
          t.update!(name: "Wet Job - Part 1", wiki_link: "https://escapefromtarkov.fandom.com/wiki/Wet_Job_-_Part_1")
        end
      end

      test "creates money unlock rows resolving the task by wiki title" do
        results = run_enrichment

        assert_equal 1, results[:items]
        rows = @item.reload.item_unlocks.of_type("money").order(:loyalty_level, :trader_name)
        assert_equal %w[Ref Peacekeeper Prapor], rows.map(&:trader_name)
        assert_equal [ 3, 4, 4 ], rows.map(&:loyalty_level)
        assert rows.all? { |row| row.task == @task }

        wiki_rows = rows.select { |row| row.source == "wiki" }
        assert_equal %w[Peacekeeper Ref], wiki_rows.map(&:trader_name).sort
        assert_predicate @item.reload, :require_unlock?
      end

      test "resolves previous/next task links from quest infoboxes" do
        results = run_enrichment

        assert_equal 1, results[:tasks]
        assert_equal @previous.id, @task.reload.previous_task_id
        assert_equal "Wet Job - Part 1", @task.previous_task_name
        assert_equal @task.id, @previous.reload.next_task_id
        assert_equal "The Cleaner", @previous.next_task_name
      end

      test "leaves records untouched when wiki content is missing" do
        fandom = FakeFandomClient.new(wikitext: { "7.62x51mm M80" => nil, "The Cleaner" => nil })

        before_count = @item.item_unlocks.count

        results = FandomEnrichmentSyncer.new(client: FakeTarkovClient.new, fandom_client: fandom).call

        assert_equal 0, results[:items]
        assert_equal 0, results[:tasks]
        assert_equal before_count, @item.reload.item_unlocks.count
      end

      private

      def run_enrichment
        fandom = FakeFandomClient.new(wikitext: {
          "7.62x51mm M80" => M80_WIKITEXT,
          "The Cleaner" => QUEST_WIKITEXT
        })
        FandomEnrichmentSyncer.new(client: FakeTarkovClient.new, fandom_client: fandom).call
      end
    end
  end
end
