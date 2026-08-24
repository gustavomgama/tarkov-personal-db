require "test_helper"

module Tarkov
  module Fandom
    class ClientExtraTest < ActiveSupport::TestCase
      test "default constructor builds a real connection" do
        assert_kind_of Faraday::Connection, Client.new.instance_variable_get(:@connection)
      end

      test "raw_wikitext resolves redirects and missing pages" do
        client = client_with_stubs do |stub|
          stub.get("/api.php") do
            [ 200, json_headers, {
              "query" => {
                "redirects" => [ { "from" => "M80", "to" => "7.62x51mm M80" } ],
                "pages" => [
                  { "title" => "7.62x51mm M80",
                    "revisions" => [ { "slots" => { "main" => { "content" => "{{Infobox ammo}}" } } } ] },
                  { "title" => "Nope Page", "missing" => true }
                ]
              }
            }.to_json ]
          end
        end

        result = client.raw_wikitext([ "M80", "Nope Page" ])

        assert_equal "{{Infobox ammo}}", result["M80"]
        assert_nil result["Nope Page"]
      end

      test "raw_wikitext raises on connection failure" do
        client = failing_client
        error = assert_raises(Client::Error) { client.raw_wikitext([ "X" ]) }
        assert_match "wikitext query failed", error.message
      end

      test "search_titles returns hit titles" do
        client = client_with_stubs do |stub|
          stub.get("/api.php") do
            [ 200, json_headers, { "query" => { "search" => [ { "title" => "AFAK" } ] } }.to_json ]
          end
        end

        assert_equal [ "AFAK" ], client.search_titles("afak")
      end

      test "search_titles raises on connection failure" do
        assert_raises(Client::Error) { failing_client.search_titles("x") }
      end

      private

      def failing_client
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/api.php") { raise Faraday::ConnectionFailed, "down" }
        end
        Client.new(connection: faraday_connection(stubs))
      end

      def json_headers
        { "Content-Type" => "application/json" }
      end

      def faraday_connection(stubs)
        Faraday.new(url: Client::BASE_URL) do |f|
          f.request :url_encoded
          f.response :json, content_type: /\bjson$/
          f.adapter :test, stubs
        end
      end

      def client_with_stubs(&block)
        Client.new(connection: faraday_connection(Faraday::Adapter::Test::Stubs.new(&block)))
      end
    end
  end
end
