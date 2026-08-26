module Tarkov
  class Client
    BASE_URL = "https://json.tarkov.dev".freeze
    REFJSONS_DIR = Pathname.new(ENV.fetch("TARKOV_REFJSONS_DIR", Rails.root.join("refjsons")))

    def self.refjsons_dir
      ENV["TARKOV_REFJSONS_DIR"] ? Pathname.new(ENV["TARKOV_REFJSONS_DIR"]) : REFJSONS_DIR
    end

    def initialize(game_mode: "regular", lang: "en", connection: nil)
      @game_mode = game_mode
      @lang = lang
      @connection = connection || Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    %w[items tasks traders barters hideout crafts hideout_en].each do |endpoint|
      define_method(endpoint) do
        fetch(endpoint)
      end
    end

    # Display-name dictionaries; memoized so one sync costs three requests.
    def localizations
      @localizations ||= Localizations.new(
        items: fetch("items_#{@lang}"),
        tasks: fetch("tasks_#{@lang}"),
        traders: fetch("traders_#{@lang}")
      )
    end

    # Local snapshots captured into refjsons/ win over the network, so the app
    # runs fully offline once they exist. Save any endpoint response as
    # refjsons/<endpoint>.json ({"data": ...}) to pin it.
    def fetch(endpoint)
      snapshot = self.class.refjsons_dir.join("#{endpoint}.json")
      return parse_snapshot(snapshot, endpoint) if snapshot.exist?

      response = @connection.get("/#{@game_mode}/#{endpoint}", { lang: @lang })
      raise Error, "tarkov.dev #{endpoint} request failed with status #{response.status}" unless response.success?

      body = response.body || {}
      body["data"] or raise Error, "tarkov.dev #{endpoint} payload missing 'data' key"
    rescue Faraday::Error => e
      raise Error, "tarkov.dev #{endpoint} request failed: #{e.message}"
    end

    class Error < StandardError; end

    private

    def parse_snapshot(path, endpoint)
      JSON.parse(path.read).fetch("data")
    rescue JSON::ParserError, KeyError => e
      raise Error, "refjsons/#{File.basename(path)} is not a valid #{endpoint} snapshot: #{e.message}"
    end
  end
end
