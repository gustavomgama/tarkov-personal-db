module Tarkov
  module Syncers
    class DenormalizedNamesRefresh < Base
      def initialize(client: nil, fandom_client: nil)
        super(client: client)
      end

      def call
        refreshed = 0
        ItemUnlock.includes(:item).find_each do |row|
          next if row.item_name == row.item.name

          row.update_columns(item_name: row.item.name)
          refreshed += 1
        end
        refreshed
      end
    end
  end
end
