require "test_helper"

class TarkovClientDefaultCtorTest < ActiveSupport::TestCase
  setup do
    @previous_dir = ENV["TARKOV_REFJSONS_DIR"]
    ENV["TARKOV_REFJSONS_DIR"] = "/nonexistent-refjsons"
  end

  teardown do
    ENV["TARKOV_REFJSONS_DIR"] = @previous_dir
  end

  test "default constructor builds a connection" do
    client = Tarkov::Client.new
    assert_kind_of Faraday::Connection, client.instance_variable_get(:@connection)
  end

  test "raises wrapped error when the network fails" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/regular/items") { raise Faraday::ConnectionFailed, "down" }
    end
    connection = Faraday.new(url: Tarkov::Client::BASE_URL) { |f| f.adapter :test, stubs }
    client = Tarkov::Client.new(connection: connection)

    error = assert_raises(Tarkov::Client::Error) { client.items }

    assert_match "request failed", error.message
  end
end
