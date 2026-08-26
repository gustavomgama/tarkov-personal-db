module Tarkov
  module Syncers
    class DenormalizedNamesRefresh < Base
      def call
        # Build lookup hashes to avoid repeated includes
        items_by_id = Item.all.index_by(&:id)
        traders_by_id = Trader.all.index_by(&:id)

        # Collect updates in memory, then apply in batch
        updates = {} # { id => { field => value } }

        ItemUnlock.find_each(batch_size: 2000) do |row|
          item = items_by_id[row.item_id]
          trader = traders_by_id[row.trader_id]
          changes = {}

          if item && row.item_name != item.name
            changes[:item_name] = item.name
          end
          if trader && row.trader_name != trader.name
            changes[:trader_name] = trader.name
          end
          updates[row.id] = changes if changes.any?
        end

        return 0 if updates.empty?

        # Batch update: group by exact change set, then bulk update each group
        grouped = {}
        updates.each do |id, value|
          key = value.to_s
          grouped[key] ||= { ids: [], values: value }
          grouped[key][:ids] << id
        end
        grouped.each_value do |group|
          ItemUnlock.where(id: group[:ids]).update_all(group[:values])
        end
        updates.size
      end
    end
  end
end
