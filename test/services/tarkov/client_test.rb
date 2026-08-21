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

    private

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
