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
        has_unlock_info = unlock.match?(UNLOCK_PATTERN)

        @item.update!(name: page_title, wiki_link: wiki_link_for(page_title))
        UnlockRows.sync!(@item, has_unlock_info ? unlock : nil)
        true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] enrichment for #{@item.tid} rejected: #{e.message}")
        false
      end

      private

      def wiki_link_for(title)
        "https://escapefromtarkov.fandom.com/wiki/#{title.tr(' ', '_')}"
      end
    end
  end
end
