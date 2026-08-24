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
          wiki_link: attrs["wikiLink"]
        }.merge(trader_price_attributes(attrs)).merge(compatibility_attributes(attrs))
      end

      def compatibility_attributes(attrs)
        properties = attrs["properties"] || {}
        types = Array(attrs["types"])
        {
          gun: types.include?("gun"),
          ammo: types.include?("ammo"),
          caliber: properties["caliber"],
          allowed_ammo: Array(properties["allowedAmmo"])
        }
      end

      # Cheapest trader buy offer; flea-market prices are deliberately ignored.
      def trader_price_attributes(attrs)
        offer = Array(attrs["buyFromTrader"]).min_by { |offer| offer["priceRUB"].to_f }
        return {} unless offer

        {
          price: offer["price"],
          currency: offer["currency"]
        }
      end
    end
  end
end
