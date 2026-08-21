module Tarkov
  module Syncers
    class FandomEnrichmentSyncer < Base
      UNLOCK_PATTERN = /task/i

      def initialize(client:, fandom_client: Tarkov::Fandom::Client.new)
        super(client: client)
        @fandom_client = fandom_client
      end

      def call
        { items: enrich_items, tasks: enrich_tasks }
      end

      private

      attr_reader :fandom_client

      def enrich_items
        records = Item.where.not(wiki_link: [ nil, "" ])
        enrich(records) do |record, parser|
          unlock = parser.infobox_params["trader"].to_s
          attributes = {
            description: parser.lead_description.presence || record.description,
            unlock_text: unlock.match?(UNLOCK_PATTERN) ? unlock : nil
          }
          Fandom::UnlockRows.sync!(record, attributes[:unlock_text])
          attributes
        end
      end

      def enrich_tasks
        records = Task.where.not(wiki_link: [ nil, "" ])
        enrich(records) do |record, parser|
          previous = parser.infobox_params["previous"].to_s
          {
            description: parser.lead_description.presence || record.description,
            previous_task_title: previous.presence
          }
        end
      end

      def enrich(scope)
        titles_by_id = scope.to_h { |record| [ record.id, title_from_link(record.wiki_link) ] }
        contents = fandom_client.raw_wikitext(titles_by_id.values.compact.uniq)
        scope.find_each.count do |record|
          title = titles_by_id.fetch(record.id)
          wikitext = contents[title]
          next false unless wikitext

          attributes = yield(record, Tarkov::Fandom::WikitextParser.new(wikitext, page_title: title))
          apply_enrichment(record, attributes)
        end
      end

      def apply_enrichment(record, attributes)
        return false if attributes.values.all?(&:nil?)

        record.update!(attributes)
        true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] enrichment for #{record.class}##{record.id} rejected: #{e.message}")
        false
      end


      def title_from_link(link)
        slug = URI(link).path.split("/").last
        return unless slug

        CGI.unescape(slug.tr("_", " "))
      rescue URI::InvalidURIError, ArgumentError
        nil
      end
    end
  end
end
