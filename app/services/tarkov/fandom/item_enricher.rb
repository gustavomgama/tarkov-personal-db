module Tarkov
  module Fandom
    class ItemEnricher
      UNLOCK_PATTERN = /task/i

      def initialize(item)
        @item = item
      end

      def apply!(wikitext, page_title)
        parser = WikitextParser.new(wikitext, page_title: page_title)
        unlock = parser.infobox_params["trader"].to_s
        attributes = {
          name: page_title,
          wiki_link: wiki_link_for(page_title),
          description: parser.lead_description.presence || @item.description,
          unlock_text: unlock.match?(UNLOCK_PATTERN) ? unlock : nil
        }
        return false if attributes.values.compact.all?(&:blank?)

        @item.update!(attributes)
        UnlockRows.sync!(@item, attributes[:unlock_text])
        true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] enrichment for #{@item.tid} rejected: #{e.message}")
        false
      end

      private

      attr_reader :item

      def wiki_link_for(title)
        "https://escapefromtarkov.fandom.com/wiki/#{title.tr(' ', '_')}"
      end
    end
  end
end
