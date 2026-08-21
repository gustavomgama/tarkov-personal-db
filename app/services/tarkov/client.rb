module Tarkov
  class Client
    BASE_URL = "https://json.tarkov.dev".freeze

    def initialize(game_mode: "regular", lang: "en", connection: nil)
      @game_mode = game_mode
      @lang = lang
      @connection = connection || Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    %w[items tasks traders barters hideout].each do |endpoint|
      define_method(endpoint) do
        fetch(endpoint)
      end
    end

    def fetch(endpoint)
      response = @connection.get("/#{@game_mode}/#{endpoint}", { lang: @lang })
      raise Error, "tarkov.dev #{endpoint} request failed with status #{response.status}" unless response.success?

      body = response.body || {}
      body["data"] or raise Error, "tarkov.dev #{endpoint} payload missing 'data' key"
    rescue Faraday::Error => e
      raise Error, "tarkov.dev #{endpoint} request failed: #{e.message}"
    end

    class Error < StandardError; end
  end
end
