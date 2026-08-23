module Tarkov
  module Syncers
    class FandomEnrichmentSyncer < Base
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
          Fandom::UnlockRows.sync!(record, unlock.match?(/task/i) ? unlock : nil)
          {}
        end
      end

      def enrich_tasks
        records = Task.where.not(wiki_link: [ nil, "" ])
        count = enrich(records) do |record, parser|
          previous_title = parser.infobox_params["previous"].to_s
          resolve_previous_task(record, previous_title)
          {}
        end
        link_next_pointers
        count
      end

      def resolve_previous_task(record, previous_title)
        previous = Task.find_by_wiki_title(previous_title)
        record.update!(
          previous_task_id: previous&.id,
          previous_task_name: previous&.name
        )
      end

      def link_next_pointers
        Task.where.not(previous_task_id: nil).find_each do |previous|
          next_task = Task.find_by(id: previous.previous_task_id)
          next unless next_task

          next_task.update!(
            next_task_id: previous.id,
            next_task_name: previous.name
          )
        end
      end

      def enrich(scope)
        titles_by_id = scope.to_h { |record| [ record.id, title_from_link(record.wiki_link) ] }
        contents = fandom_client.raw_wikitext(titles_by_id.values.compact.uniq)
        scope.count do |record|
          title = titles_by_id.fetch(record.id)
          wikitext = contents[title]
          next false unless wikitext

          yield(record, Tarkov::Fandom::WikitextParser.new(wikitext, page_title: title))
          true
        end
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
