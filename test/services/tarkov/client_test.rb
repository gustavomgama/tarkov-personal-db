require "test_helper"

module Tarkov
  class ClientTest < ActiveSupport::TestCase
    test "fetches and unwraps the data key" do
      client = client_with_stubs do |stub|
        stub.get("/regular/items") do
          [ 200, { "Content-Type" => "application/json" }, { "data" => { "items" => {} } }.to_json ]
        end
      end

      assert_equal({ "items" => {} }, client.items)
    end

    test "raises Error on non-success status" do
      client = client_with_stubs do |stub|
        stub.get("/regular/traders") { [ 500, {}, "boom" ] }
      end

      assert_raises(Client::Error) { client.traders }
    end

    test "raises Error when payload is missing the data key" do
      client = client_with_stubs do |stub|
        stub.get("/regular/hideout") do
          [ 200, { "Content-Type" => "application/json" }, { "oops" => true }.to_json ]
        end
      end

      assert_raises(Client::Error) { client.hideout }
    end

    test "localizations resolves display names from _en dictionaries" do
      client = client_with_stubs do |stub|
        stub.get("/regular/items_en") do
          [ 200, json_ct, { "data" => { "i-1 Name" => "Colt M4A1", "i-1 ShortName" => "M4A1" } }.to_json ]
        end
        stub.get("/regular/tasks_en") do
          [ 200, json_ct, { "data" => { "t-1 name" => "First in Line" } }.to_json ]
        end
        stub.get("/regular/traders_en") do
          [ 200, json_ct, { "data" => { "r-1 Nickname" => "Prapor" } }.to_json ]
        end
      end

      names = client.localizations

      assert_equal "Colt M4A1", names.item_name("i-1")
      assert_equal "M4A1", names.item_short_name("i-1")
      assert_equal "First in Line", names.task_name("t-1")
      assert_equal "Prapor", names.trader_nickname("r-1")
    end

    private

    def json_ct
      { "Content-Type" => "application/json" }
    end

    def client_with_stubs
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        yield stub
      end
      connection = Faraday.new(url: Client::BASE_URL) do |faraday|
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter :test, stubs
      end
      Client.new(connection: connection)
    end
  end
end
