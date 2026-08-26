module Tarkov
  module Syncers
    # Hideout crafts become craft-type ItemUnlock rows so craft-only items get
    # guide routes. Identity is the product item; one row per craftable item.
    # Station name/level and ingredients are stored for didactic route cards.
    class CraftSyncer < Base
      def call
        crafts = client.crafts
        return 0 if crafts.empty?

        @items_by_tid = Item.all.index_by(&:tid)
        kept = crafts.filter_map { |craft| sync_craft(craft) }

        # Everything dev-crafted that this run cannot account for is stale.
        live_ids = kept.map(&:id) +
                   crafts.filter_map { |c| Item.find_canonical(c.dig("productItem", "item").to_s)&.id }
        ItemUnlock.where(source: "dev").of_type("craft").where.not(id: kept.map(&:id))
                  .where.not(item_id: live_ids.uniq).each(&:destroy!)
        kept.size
      end

      private

      def sync_craft(craft)
        product_tid = craft.dig("productItem", "item").to_s
        item = Item.find_canonical(product_tid)
        return nil if product_tid.empty? || item.nil?

        row = ItemUnlock.where(item_id: item.id, source: "dev").of_type("craft").first ||
              ItemUnlock.new(item_id: item.id, item_name: item.name, source: "dev",
                             unlock_types: [ "craft" ])
        upsert!(row, {
          item_name: item.name,
          station: station_name(craft["station"]),
          station_level: craft["level"],
          required_items: craft_ingredients(craft)
        })
        item.update!(craft: true)
        row
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] craft skipped for #{product_tid}: #{e.message}")
        nil
      end

      def station_name(station_id)
        area = hideout[station_id.to_s]
        return "Hideout" unless area.is_a?(Hash)

        localized[area["name"]].presence ||
          area["normalizedName"].to_s.tr("_", " ").capitalize
      end

      # Consumed ingredients only; tools are displayed differently and are not
      # part of the recipe cost.
      def craft_ingredients(craft)
        Array(craft["requiredItems"]).filter_map do |req|
          next if req.dig("attributes", "tool")

          raw_tid = req["item"].to_s
          resolved_tid = ItemAlias.resolve(raw_tid)
          ingredient = @items_by_tid[resolved_tid]
          {
            "tid" => resolved_tid,
            "name" => ingredient&.name || names.item_name(raw_tid) || raw_tid,
            "icon_link" => ingredient&.icon_link,
            "count" => req["count"] || 1
          }
        end
      end

      def hideout
        @hideout ||= client.hideout
      end

      def names
        @names ||= client.localizations
      end

      def localized
        @localized ||= client.hideout_en
      end
    end
  end
end
