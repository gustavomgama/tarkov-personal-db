module Tarkov
  module Fandom
    class Client
      BASE_URL = "https://escapefromtarkov.fandom.com/api.php".freeze
      BATCH_SIZE = 50

      def initialize(connection: nil)
        @connection = connection || Faraday.new(url: BASE_URL) do |conn|
          conn.request :url_encoded
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      def pages(titles)
        titles.each_slice(BATCH_SIZE).each_with_object({}) do |batch, resolved|
          resolved.merge!(resolve_batch(batch))
        end
      end

      def raw_wikitext(titles)
        titles.each_slice(BATCH_SIZE).each_with_object({}) do |batch, contents|
          response = @connection.get("", wikitext_params(batch))
          raise Error, "fandom wikitext query failed with status #{response.status}" unless response.success?

          body = response.body
          final_titles = redirect_map(body).merge(normalize_map(body))
          pages = body.fetch("query").fetch("pages")

          batch.each do |title|
            target = final_titles[title] || title
            page = pages.find { |candidate| candidate["title"] == target }
            contents[title] = page && !page["missing"] ? page.dig("revisions", 0, "slots", "main", "content") : nil
          end
        end
      rescue Faraday::Error => e
        raise Error, "fandom wikitext query failed: #{e.message}"
      end

      GAMEVERSION_TEMPLATE = "Template:Gameversion".freeze

      def latest_game_version
        response = @connection.get("", wikitext_params([ GAMEVERSION_TEMPLATE ]).except("redirects"))
        raise Error, "fandom gameversion query failed with status #{response.status}" unless response.success?

        wikitext = response.body.dig("query", "pages", 0, "revisions", 0, "slots", "main", "content")
        version = wikitext.to_s.match(/\d+(?:\.\d+)+/).to_s
        raise Error, "could not parse game version from #{GAMEVERSION_TEMPLATE}" if version.empty?

        version
      rescue Faraday::Error => e
        raise Error, "fandom gameversion query failed: #{e.message}"
      end

      def search_titles(query, limit: 5)
        response = @connection.get("", {
          action: "query",
          format: "json",
          formatversion: "2",
          list: "search",
          srnamespace: "0",
          srlimit: limit.to_s,
          srsearch: query
        })
        raise Error, "fandom search failed with status #{response.status}" unless response.success?

        response.body.dig("query", "search").to_a.map { |hit| hit["title"] }
      rescue Faraday::Error => e
        raise Error, "fandom search failed: #{e.message}"
      end

      def category_members(category)
        members = []
        continuation = nil
        loop do
          response = @connection.get("", category_params(category, continuation))
          raise Error, "fandom category query failed with status #{response.status}" unless response.success?

          data = response.body.fetch("query").fetch("categorymembers")
          members.concat(data.map { |member| member["title"] })
          continuation = response.body.dig("continue", "cmcontinue")
          break if continuation.nil?
        end
        members
      rescue Faraday::Error => e
        raise Error, "fandom category query failed: #{e.message}"
      end

      private

      def resolve_batch(titles)
        response = @connection.get("", pages_params(titles))
        raise Error, "fandom pages query failed with status #{response.status}" unless response.success?

        body = response.body
        final_titles = redirect_map(body)
        pages = body.fetch("query").fetch("pages")

        titles.to_h do |title|
          normalized = normalize_map(body)[title] || title
          target = final_titles[normalized] || normalized
          page = pages.find { |candidate| candidate["title"] == target }
          [ title, page && !page["missing"] ? target : nil ]
        end
      rescue Faraday::Error => e
        raise Error, "fandom pages query failed: #{e.message}"
      end

      def pages_params(titles)
        {
          action: "query",
          format: "json",
          formatversion: "2",
          redirects: "1",
          titles: titles.join("|")
        }
      end

      def wikitext_params(titles)
        pages_params(titles).merge(
          prop: "revisions",
          rvprop: "content",
          rvslots: "main"
        )
      end

      def category_params(category, continuation)
        params = {
          action: "query",
          format: "json",
          formatversion: "2",
          list: "categorymembers",
          cmtitle: category,
          cmlimit: "max",
          cmtype: "page"
        }
        continuation ? params.merge(cmcontinue: continuation) : params
      end

      def normalize_map(body)
        (body.dig("query", "normalized") || []).to_h { |entry| [ entry["from"], entry["to"] ] }
      end

      def redirect_map(body)
        (body.dig("query", "redirects") || []).to_h { |entry| [ entry["from"], entry["to"] ] }
      end

      class Error < StandardError; end
    end
  end
end
