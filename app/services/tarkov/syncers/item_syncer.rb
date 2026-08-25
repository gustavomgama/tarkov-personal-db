module Tarkov
  module Syncers
    class ItemSyncer < Base
      def call
        names = client.localizations
        items = (client.items["items"] || {})
        deriver = CategoryDeriver.new(items.values.group_by { |a| a["normalizedName"].to_s })
        items.each_value.sum do |attrs|
          upsert!(find_item(attrs), item_attributes(attrs, names, deriver)) ? 1 : 0
        end
      end

      private

      def find_item(attrs)
        Item.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def item_attributes(attrs, names, deriver)
        {
          name: names.item_name(attrs.fetch("id")) || attrs["name"],
          icon_link: attrs["image512pxLink"] || attrs["iconLink"],
          image_link: attrs["image8xLink"] || attrs["inspectImageLink"] || attrs["baseImageLink"],
          wiki_link: attrs["wikiLink"],
          categories: deriver.derive(attrs)
        }.merge(trader_price_attributes(attrs)).merge(compatibility_attributes(attrs)).merge(compat_attributes(attrs))
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

      # Slot/attachment relations used by the Compatibility section.
      def compat_attributes(attrs)
        props = attrs["properties"] || {}
        types = Array(attrs["types"])
        plates = Array(props["armorSlots"]).flat_map { |slot| slot["allowedPlates"].to_a }.uniq
        compat = {}
        compat["plates"] = plates if plates.any?
        compat["kind"] = "plate" if types.include?("armorPlate")
        compat["kind"] = "headset" if types.include?("headphones")
        compat["no_headset"] = props["blocksHeadset"] == true
        { compat: compat }
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
