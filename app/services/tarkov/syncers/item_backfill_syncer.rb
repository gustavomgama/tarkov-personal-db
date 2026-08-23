module Tarkov
  module Syncers
    class ItemBackfillSyncer < Base
      THREAD_COUNT = Integer(ENV.fetch("BACKFILL_THREADS", "8"))

      def initialize(client:, fandom_client: Tarkov::Fandom::Client.new)
        super(client: client)
        @fandom_client = fandom_client
      end

      # Network lookups run in parallel; DB writes stay on the main thread so they
      # play nicely with SQLite and the surrounding sync transaction.
      def call
        collect_matches.count do |item, title, wikitext|
          Fandom::ItemEnricher.new(item).apply!(wikitext, title)
        end
      end

      private

      attr_reader :fandom_client

      def nameless_items
        Item.where("name LIKE ? OR name LIKE ? OR name = ''", "% Name", "% ShortName")
            .where.not(quest_item: true)
      end

      def collect_matches
        names_by_tid = client.items.fetch("items", {}).transform_values { |attrs| attrs["normalizedName"].to_s }
        queue = Queue.new
        nameless_items.find_each { |item| queue << item }
        found = Queue.new

        workers = Array.new(THREAD_COUNT) do
          Thread.new do
            loop do
              item = queue.pop(true)
              if (match = match_for(item, names_by_tid[item.tid]))
                found << [ item, match[0], match[1] ]
              end
            end
          rescue ThreadError
            nil # queue drained
          end
        end
        workers.each(&:join)
        drain(found)
      end

      def match_for(item, normalized_name)
        return nil if normalized_name.blank?

        candidates = fandom_client.search_titles(normalized_name.tr("-", " "))
        contents = fandom_client.raw_wikitext(candidates)
        candidates.each do |title|
          wikitext = contents[title]
          next unless wikitext

          parser = Fandom::WikitextParser.new(wikitext, page_title: title)
          return [ title, wikitext ] if parser.infobox_params["node"] == item.tid
        end
        nil
      rescue Fandom::Client::Error => e
        Rails.logger.warn("[tarkov:sync] backfill lookup for #{item.tid} failed: #{e.message}")
        nil
      end

      def drain(queue)
        drained = []
        loop { drained << queue.pop(true) }
      rescue ThreadError
        drained
      end
    end
  end
end
