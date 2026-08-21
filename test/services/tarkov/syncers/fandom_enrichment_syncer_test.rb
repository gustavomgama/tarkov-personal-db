require "test_helper"

module Tarkov
  module Syncers
    class FandomEnrichmentSyncerTest < ActiveSupport::TestCase
      M80_WIKITEXT = <<~WIKI.freeze
        {{Infobox ammo
        |weight             =0.024 kg
        |trader             =[[Peacekeeper]] LL4, after completing his task [[The Cleaner]]
        |node               =58dd3ad986f77403051cba8f
        }}

        '''{{PAGENAME}}''' is a [[7.62x51mm NATO|cartridge]] in ''[[Escape from Tarkov]]''.
      WIKI

      QUEST_WIKITEXT = <<~WIKI.freeze
        {{Infobox quest
        |given by     =[[Peacekeeper]]
        |previous     =[[Wet Job - Part 1]]
        }}

        '''{{PAGENAME}}''' is a [[Quests|Quest]] in ''[[Escape from Tarkov]]''.
      WIKI

      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
        @item = Item.find_by!(tid: "item-1")
        @item.update!(wiki_link: "https://escapefromtarkov.fandom.com/wiki/7.62x51mm_M80")
        @task = Task.find_by!(tid: "task-1")
        @task.update!(wiki_link: "https://escapefromtarkov.fandom.com/wiki/The_Cleaner")
      end

      test "enriches items with wiki description and unlock text" do
        results = run_enrichment

        assert_equal 1, results[:items]
        assert_equal "7.62x51mm M80 is a cartridge in Escape from Tarkov.", @item.reload.description
        assert_equal "Peacekeeper LL4, after completing his task The Cleaner", @item.unlock_text
      end

      test "enriches tasks with description and previous quest title" do
        results = run_enrichment

        assert_equal 1, results[:tasks]
        assert_equal "The Cleaner is a Quest in Escape from Tarkov.", @task.reload.description
        assert_equal "Wet Job - Part 1", @task.previous_task_title
      end

      test "leaves records untouched when wiki content is missing" do
        fandom = FakeFandomClient.new(wikitext: { "7.62x51mm M80" => nil, "The Cleaner" => nil })

        results = FandomEnrichmentSyncer.new(client: FakeTarkovClient.new, fandom_client: fandom).call

        assert_equal 0, results[:items]
        assert_equal 0, results[:tasks]
        assert_equal "Assault rifle", @item.reload.description
        assert_nil @item.reload.unlock_text
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
