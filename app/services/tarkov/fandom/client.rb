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
          body = api_get(wikitext_params(batch), "fandom wikitext query failed")
          final_titles = redirect_map(body).merge(normalize_map(body))
          pages = body.fetch("query").fetch("pages")

          batch.each do |title|
            target = final_titles[title] || title
            contents[title] = content_of(page_with_title(pages, target))
          end
        end
      end

      GAMEVERSION_TEMPLATE = "Template:Gameversion".freeze

      def latest_game_version
        body = api_get(wikitext_params([ GAMEVERSION_TEMPLATE ]).except("redirects"),
                       "fandom gameversion query failed")
        wikitext = body.dig("query", "pages", 0, "revisions", 0, "slots", "main", "content")
        version = wikitext.to_s.match(/\d+(?:\.\d+)+/).to_s
        raise Error, "could not parse game version from #{GAMEVERSION_TEMPLATE}" if version.empty?

        version
      end

      def search_titles(query, limit: 5)
        body = api_get({
          action: "query",
          format: "json",
          formatversion: "2",
          list: "search",
          srnamespace: "0",
          srlimit: limit.to_s,
          srsearch: query
        }, "fandom search failed")

        body.dig("query", "search").to_a.map { |hit| hit["title"] }
      end

      def category_members(category)
        members = []
        continuation = nil
        loop do
          body = api_get(category_params(category, continuation), "fandom category query failed")
          members.concat(body.fetch("query").fetch("categorymembers").map { |member| member["title"] })
          continuation = body.dig("continue", "cmcontinue")
          break if continuation.nil?
        end
        members
      end

      private

      def resolve_batch(titles)
        body = api_get(pages_params(titles), "fandom pages query failed")
        redirects = redirect_map(body)
        normalizations = normalize_map(body)
        pages = body.fetch("query").fetch("pages")

        titles.to_h do |title|
          normalized = normalizations[title] || title
          target = redirects[normalized] || normalized
          [ title, live_page?(pages, target) ? target : nil ]
        end
      end

      # One shared GET + status check + error wrapping for every MediaWiki query.
      def api_get(params, description)
        response = @connection.get("", params)
        raise Error, "#{description} with status #{response.status}" unless response.success?

        response.body
      rescue Faraday::Error => e
        raise Error, "#{description}: #{e.message}"
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

      def page_with_title(pages, title)
        pages.find { |candidate| candidate["title"] == title }
      end

      def live_page?(pages, title)
        page = page_with_title(pages, title)
        page && !page["missing"]
      end

      def content_of(page)
        page && !page["missing"] ? page.dig("revisions", 0, "slots", "main", "content") : nil
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
