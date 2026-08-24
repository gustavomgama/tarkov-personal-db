module Tarkov
  module Syncers
    # Hideout crafts become craft-type ItemUnlock rows so craft-only items get
    # guide routes. Identity is the product item; one row per craftable item.
    class CraftSyncer < Base
      def call
        crafts = client.crafts
        return 0 if crafts.empty?

        kept = []
        crafts.each do |craft|
          row = sync_craft(craft)
          kept << row if row
        end

        # Everything dev-crafted that this run cannot account for is stale.
        live_ids = kept.map(&:id) +
                   crafts.filter_map { |c| Item.find_by(tid: c.dig("productItem", "item").to_s)&.id }
        ItemUnlock.where(source: "dev").of_type("craft").where.not(id: kept.map(&:id))
                  .where.not(item_id: live_ids.uniq).each(&:destroy!)
        kept.size
      end

      private

      def sync_craft(craft)
        product_tid = craft.dig("productItem", "item").to_s
        item = Item.find_by(tid: product_tid)
        return nil if product_tid.empty? || item.nil?

        row = ItemUnlock.where(item_id: item.id, source: "dev").of_type("craft").first ||
              ItemUnlock.new(item_id: item.id, item_name: item.name, source: "dev",
                             unlock_types: [ "craft" ])
        upsert!(row, { item_name: item.name })
        item.update!(craft: true)
        row
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] craft skipped for #{product_tid}: #{e.message}")
        nil
      end
    end
  end
end
