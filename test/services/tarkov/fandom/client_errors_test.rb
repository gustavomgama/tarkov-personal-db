require "test_helper"

module Tarkov
  module Fandom
    class ClientErrorsTest < ActiveSupport::TestCase
      test "search raises on non-success status" do
        client = client_with_stubs do |stub|
          stub.get("/api.php") { [ 500, {}, "boom" ] }
        end

        assert_raises(Client::Error) { client.search_titles("x") }
      end

      test "gameversion raises on connection failure" do
        assert_raises(Client::Error) { failing_client.latest_game_version }
      end

      test "category_members raises on connection failure" do
        assert_raises(Client::Error) { failing_client.category_members("Category:Traders") }
      end

      test "pages raises on connection failure" do
        assert_raises(Client::Error) { failing_client.pages([ "X" ]) }
      end

      private

      def failing_client
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/api.php") { raise Faraday::ConnectionFailed, "down" }
        end
        Client.new(connection: faraday_connection(stubs))
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
