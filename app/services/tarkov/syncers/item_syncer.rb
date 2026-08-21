module Tarkov
  module Syncers
    class ItemSyncer < Base
      def call
        payload = client.items
        categories = category_names(payload)
        items = payload["items"] || {}
        items.each_value.sum { |attrs| upsert!(find_item(attrs), item_attributes(attrs, categories)) ? 1 : 0 }
      end

      private

      def find_item(attrs)
        Item.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def item_attributes(attrs, categories)
        {
          name: attrs["name"],
          short_name: attrs["shortName"],
          description: attrs["description"],
          category: category_for(attrs["categories"], categories),
          types: attrs["types"] || [],
          width: attrs["width"],
          height: attrs["height"],
          weight: attrs["weight"],
          icon_link: attrs["iconLink"],
          grid_image_link: attrs["gridImageLink"],
          wiki_link: attrs["wikiLink"]
        }
      end

      def category_names(payload)
        (payload["itemCategories"] || {}).transform_values { |category| category["normalizedName"] }
      end

      def category_for(category_ids, categories)
        Array(category_ids).filter_map { |tid| categories[tid] }.first
      end
    end
  end
end
