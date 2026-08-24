require "test_helper"

module Tarkov
  module Syncers
    class BackfillErrorTest < ActiveSupport::TestCase
      test "backfill tolerates fandom search failures" do
        Item.create!(tid: "i-bf", name: "6617bee Name")
        client = FakeTarkovClient.new(items: { "items" => {
          "i-bf" => { "id" => "i-bf", "normalizedName" => "thing", "name" => "6617bee Name" }
        } })
        failing = Object.new
        def failing.search_titles(*)
          raise Tarkov::Fandom::Client::Error, "search down"
        end
        def failing.raw_wikitext(titles)
          titles.to_h { |t| [ t, nil ] }
        end

        count = ItemBackfillSyncer.new(client: client, fandom_client: failing).call

        assert_equal 0, count
      end
    end
  end
end
