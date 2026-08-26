require "test_helper"
require "json"

module Tarkov
  class ClientTest < ActiveSupport::TestCase
    setup do
      # Network-path tests must not be intercepted by local snapshots.
      @previous_dir = ENV["TARKOV_REFJSONS_DIR"]
      ENV["TARKOV_REFJSONS_DIR"] = "/nonexistent-refjsons"
    end

    teardown do
      ENV["TARKOV_REFJSONS_DIR"] = @previous_dir
    end

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

    test "local refjsons snapshots win over the network" do
      dir = Dir.mktmpdir
      ENV["TARKOV_REFJSONS_DIR"] = dir
      File.write(File.join(dir, "barters.json"), JSON.generate({ "data" => [ { "id" => "local-1" } ] }))
      client = client_with_stubs do |stub|
        stub.get("/regular/barters") { [ 500, {}, "network must not be touched" ] }
      end

      assert_equal [ { "id" => "local-1" } ], client.barters
    ensure
      FileUtils.remove_entry(dir) if dir
    end

    test "a corrupt snapshot raises a descriptive client error" do
      dir = Dir.mktmpdir
      ENV["TARKOV_REFJSONS_DIR"] = dir
      File.write(File.join(dir, "barters.json"), "{nope")
      client = Client.new(connection: Faraday.new { |f| f.adapter Faraday.default_adapter })

      error = assert_raises(Client::Error) { client.barters }

      assert_match(/barters\.json/, error.message)
    ensure
      FileUtils.remove_entry(dir) if dir
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
