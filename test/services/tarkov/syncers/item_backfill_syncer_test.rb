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

        '''{{PAGENAME}}''' is a [[stock]].
      WIKI

      setup do
        @client = FakeTarkovClient.new(items: item_payload)
        ItemSyncer.new(client: @client).call
        @item = Item.find_by!(tid: "item-1")
        @item.update!(name: "5447a9cd4bdc2dbd208b4567 Name", wiki_link: nil)
      end

      test "backfills nameless item when search hit node matches" do
        fandom = FakeFandomClient.new(
          wikitext: { "M4A1 Carbine" => WIKITEXT },
          search_results: { "colt m4a1" => [ "Wrong Page", "M4A1 Carbine" ] }
        )

        count = ItemBackfillSyncer.new(client: @client, fandom_client: fandom).call

        assert_equal 1, count
        assert_equal "M4A1 Carbine", @item.reload.name
        assert_equal "https://escapefromtarkov.fandom.com/wiki/M4A1_Carbine", @item.wiki_link
        assert_equal "Mechanic", @item.item_unlocks.sole.trader_name
      end

      test "skips items whose search hits have mismatched node ids" do
        fandom = FakeFandomClient.new(
          wikitext: { "Other Item" => WIKITEXT.gsub("item-1", "other-tid") },
          search_results: { "colt m4a1" => [ "Other Item" ] }
        )

        count = ItemBackfillSyncer.new(client: @client, fandom_client: fandom).call

        assert_equal 0, count
        assert_equal "5447a9cd4bdc2dbd208b4567 Name", @item.reload.name
      end
    end
  end
end
