module Tarkov
  module Syncers
    class ItemSyncer < Base
      def call
        items = (client.items["items"] || {})
        items.each_value.sum do |attrs|
          upsert!(find_item(attrs), item_attributes(attrs)) ? 1 : 0
        end
      end

      private

      def find_item(attrs)
        Item.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def item_attributes(attrs)
        {
          name: attrs["name"],
          icon_link: attrs["iconLink"],
          grid_image_link: attrs["gridImageLink"],
          wiki_link: attrs["wikiLink"]
        }
      end
    end
  end
end
