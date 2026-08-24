module Tarkov
  module Syncers
    # Populates tasks.previous_task_id/name from the wiki infobox `previous`
    # param. The dev payload carries requirement edges for only ~40% of tasks;
    # the wiki chain links are the source of truth for the rest. This is the
    # single sanctioned wiki write: structural chain data only.
    class TaskChainSyncer < Base
      def initialize(client:, fandom_client: Tarkov::Fandom::Client.new)
        super(client: client)
        @fandom_client = fandom_client
      end

      def call
        updated = 0
        tasks_with_pages.find_each do |task|
          updated += 1 if sync_chain_link(task)
        end
        updated
      end

      private

      attr_reader :fandom_client

      def tasks_with_pages
        Task.where.not(wiki_link: [ nil, "" ])
      end

      def sync_chain_link(task)
        title = title_from_link(task.wiki_link)
        return false if title.blank?

        wikitext = wikitexts[title]
        previous_title = wikitext ? parser(wikitext).infobox_params["previous"] : nil
        previous = previous_title.present? ? Task.find_by_wiki_title(previous_title) : nil
        return false if task.previous_task_id == previous&.id &&
                        task.previous_task_name == (previous&.name || previous_title.presence)

        task.update!(previous_task_id: previous&.id,
                     previous_task_name: previous&.name || previous_title.presence)
        true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] chain link for #{task.tid} skipped: #{e.message}")
        false
      end

      def wikitexts
        @wikitexts ||= begin
          titles = tasks_with_pages.filter_map { |task| title_from_link(task.wiki_link) }
                                   .uniq
          @fandom_client.raw_wikitext(titles)
        end
      end

      def parser(wikitext)
        Fandom::WikitextParser.new(wikitext.to_s, page_title: "")
      end

      def title_from_link(link)
        slug = link.to_s[/\/wiki\/(.+)\z/, 1]
        return "" if slug.blank?

        URI.decode_www_form_component(slug).tr("_", " ")
      end
    end
  end
end
