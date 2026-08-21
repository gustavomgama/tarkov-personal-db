require "test_helper"

module Tarkov
  module Syncers
    class ItemBackfillSyncerTest < ActiveSupport::TestCase
      WIKITEXT = <<~WIKI.freeze
        {{Infobox weapon
        |type =Stock
        |node =item-1
        |trader =[[Mechanic]] LL2, after completing his task [[Setup]]
        }}

        '''{{PAGENAME}}''' is a [[stock]] in ''[[Escape from Tarkov]]''.
      WIKI

      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        @item = Item.find_by!(tid: "item-1")
        @item.update!(name: "5447a9cd4bdc2dbd208b4567 Name", wiki_link: nil, normalized_name: "m4a1-carbine")
      end

      test "backfills nameless item when search hit node matches" do
        fandom = FakeFandomClient.new(
          wikitext: { "M4A1 Carbine" => WIKITEXT },
          search_results: { "m4a1 carbine" => [ "Wrong Page", "M4A1 Carbine" ] }
        )

        count = ItemBackfillSyncer.new(client: FakeTarkovClient.new, fandom_client: fandom).call

        assert_equal 1, count
        assert_equal "M4A1 Carbine", @item.reload.name
        assert_equal "https://escapefromtarkov.fandom.com/wiki/M4A1_Carbine", @item.wiki_link
        assert_equal "M4A1 Carbine is a stock in Escape from Tarkov.", @item.description
        assert_equal "Mechanic LL2, after completing his task Setup", @item.unlock_text
        unlock = @item.item_unlocks.sole
        assert_equal "Mechanic", unlock.trader_title
        assert_equal 2, unlock.loyalty_level
      end

      test "skips items whose search hits have mismatched node ids" do
        fandom = FakeFandomClient.new(
          wikitext: { "Other Item" => WIKITEXT.gsub("item-1", "other-tid") },
          search_results: { "m4a1 carbine" => [ "Other Item" ] }
        )

        count = ItemBackfillSyncer.new(client: FakeTarkovClient.new, fandom_client: fandom).call

        assert_equal 0, count
        assert_equal "5447a9cd4bdc2dbd208b4567 Name", @item.reload.name
      end

      test "skips items with no normalized name to search" do
        @item.update!(normalized_name: nil)
        fandom = FakeFandomClient.new

        count = ItemBackfillSyncer.new(client: FakeTarkovClient.new, fandom_client: fandom).call

        assert_equal 0, count
        assert_empty fandom.wikitext_queries
      end
    end
  end
end
