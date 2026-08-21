module Tarkov
  module Syncers
    class FandomNameSyncer < Base
      TRADERS_CATEGORY = "Category:Traders".freeze

      def initialize(client:, fandom_client: Tarkov::Fandom::Client.new)
        super(client: client)
        @fandom_client = fandom_client
      end

      def call
        {
          items: sync_item_names,
          tasks: sync_task_names,
          traders: sync_trader_names,
          stations: sync_station_names
        }
      end

      private

      attr_reader :fandom_client

      def sync_item_names
        records_with_titles(Item.where.not(wiki_link: nil)) do |item|
          title_from_link(item.wiki_link)
        end
      end

      def sync_task_names
        records_with_titles(Task.where.not(wiki_link: nil)) do |task|
          title_from_link(task.wiki_link)
        end
      end

      def sync_trader_names
        titles_by_key = fandom_client.category_members(TRADERS_CATEGORY).to_h do |title|
          [ wiki_key(title), title ]
        end
        Trader.find_each.count do |trader|
          title = titles_by_key[wiki_key(trader.normalized_name.to_s)]
          apply_name(trader, title)
        end
      end

      def sync_station_names
        # The wiki has no per-station pages (all redirect to the Hideout article),
        # so station names come from a curated map instead.
        names = HideoutStation::DISPLAY_NAMES
        HideoutStation.find_each.count do |station|
          apply_name(station, names[station.normalized_name])
        end
      end

      def records_with_titles(scope)
        titles_by_id = scope.to_h { |record| [ record.id, yield(record) ] }
        resolved = fandom_client.pages(titles_by_id.values.compact.uniq)
        scope.count do |record|
          title = titles_by_id.fetch(record.id)
          apply_name(record, title ? resolved[title] : nil)
        end
      end

      def apply_name(record, canonical_title)
        return false unless canonical_title

        record.update!(name: canonical_title)
        true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] fandom name for #{record.class}##{record.id} rejected: #{e.message}")
        false
      end

      def title_from_link(link)
        slug = URI(link).path.split("/").last
        return unless slug

        CGI.unescape(slug.tr("_", " "))
      rescue URI::InvalidURIError, ArgumentError
        nil
      end

      def wiki_key(title)
        title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
      end
    end
  end
end
