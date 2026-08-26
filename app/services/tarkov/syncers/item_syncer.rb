module Tarkov
  module Syncers
    class ItemSyncer < Base
      def call
        names = client.localizations
        items = (client.items["items"] || {})
        collapse = Tarkov::PresetCollapse.new(items.values)
        deriver = CategoryDeriver.new(items.values.group_by { |a| a["normalizedName"].to_s })
        count = items.each_value.sum do |attrs|
          next 0 if collapse.drop?(attrs["id"])
          next 0 if historical_item?(attrs, names)

          merged = collapse.merge_base_into(attrs)
          upsert!(find_item(merged), item_attributes(merged, names, deriver)) ? 1 : 0
        end
        collapse.remap_records!
        count
      end

      private

      # Retired content (fandom "Historical content") never becomes a row.
      def historical_item?(attrs, names)
        Tarkov::HistoricalContent.historical?(attrs["name"]) ||
          Tarkov::HistoricalContent.historical?(names.item_name(attrs["id"]))
      end

      def find_item(attrs)
        Item.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def item_attributes(attrs, names, deriver)
        {
          name: names.item_name(attrs.fetch("id")) || attrs["name"],
          slug: attrs["normalizedName"],
          icon_link: attrs["image512pxLink"] || attrs["iconLink"],
          image_link: attrs["image8xLink"] || attrs["inspectImageLink"] || attrs["baseImageLink"],
          wiki_link: attrs["wikiLink"],
          categories: deriver.derive(attrs)
        }.merge(trader_price_attributes(attrs))
         .merge(compatibility_attributes(attrs))
         .merge(compat_attributes(attrs))
         .merge(ballistics_attributes(attrs))
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

      # Ballistics data: penetration power and damage for ammo, armor class for armor/helmets.
      def ballistics_attributes(attrs)
        props = attrs["properties"] || {}
        types = Array(attrs["types"])
        result = {}

        if types.include?("ammo")
          result[:penetration_power] = props["penetrationPower"]
          result[:damage] = props["damage"]
        end

        if (types.include?("armor") || types.include?("helmet")) && props["class"]
          result[:armor_class] = props["class"]
        end

        result
      end
    end
  end
end
