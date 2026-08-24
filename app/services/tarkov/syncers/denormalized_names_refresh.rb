module Tarkov
  module Syncers
    class DenormalizedNamesRefresh < Base
      def call
        refreshed = 0
        ItemUnlock.includes(:item, :trader).find_each do |row|
          updates = {}
          updates[:item_name] = row.item.name if row.item_name != row.item.name
          if row.trader && row.trader_name != row.trader.name
            updates[:trader_name] = row.trader.name
          end
          next if updates.empty?

          row.update_columns(updates)
          refreshed += 1
        end
        refreshed
      end
    end
  end
end
