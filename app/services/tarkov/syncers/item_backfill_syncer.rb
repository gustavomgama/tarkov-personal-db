module Tarkov
  module Syncers
    class ItemBackfillSyncer < Base
      THREAD_COUNT = Integer(ENV.fetch("BACKFILL_THREADS", "8"))

      def initialize(client:, fandom_client: Tarkov::Fandom::Client.new)
        super(client: client)
        @fandom_client = fandom_client
      end

      def call
        queue = Queue.new
        nameless_items.find_each { |item| queue << item }
        results = Queue.new

        workers = Array.new(THREAD_COUNT) do
          Thread.new do
            loop do
              item = queue.pop(true)
              results << item.tid if backfill(item, fandom_client)
            end
          rescue ThreadError
            nil # queue drained
          end
        end
        workers.each(&:join)
        results.size
      end

      private

      attr_reader :fandom_client

      def nameless_items
        Item.where("name LIKE ? OR name LIKE ? OR name = ''", "% Name", "% ShortName")
            .where.not(normalized_name: [ nil, "" ])
      end

      def backfill(item, fandom_client)
        candidates = fandom_client.search_titles(item.normalized_name.tr("-", " "))
        contents = fandom_client.raw_wikitext(candidates)
        candidates.each do |title|
          wikitext = contents[title]
          next unless wikitext

          parser = Fandom::WikitextParser.new(wikitext, page_title: title)
          next unless parser.infobox_params["node"] == item.tid

          return Fandom::ItemEnricher.new(item).apply!(wikitext, title)
        end
        false
      rescue Fandom::Client::Error => e
        Rails.logger.warn("[tarkov:sync] backfill for #{item.tid} failed: #{e.message}")
        false
      end
    end
  end
end
