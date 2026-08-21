require "test_helper"

module Tarkov
  module Fandom
    class ClientTest < ActiveSupport::TestCase
      API_PATH = "/api.php".freeze

      test "resolves pages, redirects and missing titles" do
        client = client_with_stubs do |stub|
          stub.get(API_PATH) do |env|
            assert_equal "Colt M4A1|M4A1|Nope", env.params["titles"]
            [ 200, json_headers, {
              "query" => {
                "normalized" => [ { "from" => "Nope", "to" => "Nope Page" } ],
                "redirects" => [ { "from" => "M4A1", "to" => "Colt M4A1 5.56x45 assault rifle" } ],
                "pages" => [
                  { "pageid" => 1, "title" => "Colt M4A1 5.56x45 assault rifle" },
                  { "title" => "Nope Page", "missing" => true }
                ]
              }
            }.to_json ]
          end
        end

        result = client.pages([ "Colt M4A1", "M4A1", "Nope" ])

        assert_equal(
          {
            "Colt M4A1" => nil,
            "M4A1" => "Colt M4A1 5.56x45 assault rifle",
            "Nope" => nil
          },
          result
        )
      end

      test "batches titles in slices of 50" do
        requested = []
        stubs = Faraday::Adapter::Test::Stubs.new
        3.times do
          stubs.get(API_PATH) do |env|
            requested.concat(env.params["titles"].split("|"))
            [ 200, json_headers, { "query" => { "pages" => [] } }.to_json ]
          end
        end
        client = Client.new(connection: faraday_connection(stubs))

        titles = (1..120).map(&:to_s)
        result = client.pages(titles)

        assert_equal 120, requested.size
        assert_equal((1..120).map(&:to_s).sort, result.keys.sort)
        assert result.values.all?(&:nil?)
      end

      test "follows cmcontinue pagination for category members" do
        client = client_with_stubs do |stub|
          stub.get(API_PATH) do
            [ 200, json_headers, {
              "continue" => { "cmcontinue" => "page2" },
              "query" => { "categorymembers" => [ { "title" => "Prapor" } ] }
            }.to_json ]
          end
          stub.get(API_PATH) do |env|
            assert_equal "page2", env.params["cmcontinue"]
            [ 200, json_headers, { "query" => { "categorymembers" => [ { "title" => "Skier" } ] } }.to_json ]
          end
        end

        assert_equal %w[Prapor Skier], client.category_members("Category:Traders")
      end

      test "parses latest game version from the Gameversion template" do
        client = client_with_stubs do |stub|
          stub.get(API_PATH) do |env|
            assert_equal "Template:Gameversion", env.params["titles"]
            [ 200, json_headers, {
              "query" => {
                "pages" => [
                  { "pageid" => 1, "title" => "Template:Gameversion",
                    "revisions" => [ { "slots" => { "main" => { "content" => "[[Changelog|1.1.0.1.46911]]" } } } ] }
                ]
              }
            }.to_json ]
          end
        end

        assert_equal "1.1.0.1.46911", client.latest_game_version
      end

      test "raises when game version cannot be parsed" do
        client = client_with_stubs do |stub|
          stub.get(API_PATH) do
            [ 200, json_headers, { "query" => { "pages" => [] } }.to_json ]
          end
        end

        assert_raises(Client::Error) { client.latest_game_version }
      end

      private

      def json_headers
        { "Content-Type" => "application/json" }
      end

      def faraday_connection(stubs)
        Faraday.new(url: Client::BASE_URL) do |faraday|
          faraday.request :url_encoded
          faraday.response :json, content_type: /\bjson$/
          faraday.adapter :test, stubs
        end
      end

      def client_with_stubs(&block)
        stubs = Faraday::Adapter::Test::Stubs.new(&block)
        Client.new(connection: faraday_connection(stubs))
      end
    end
  end
end
