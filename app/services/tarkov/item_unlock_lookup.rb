module Tarkov
  class ItemUnlockLookup
    def initialize(item)
      @item = item
    end

    def call
      {
        item: @item,
        unlock_paths: UnlockPathResolver.new(@item).resolve,
        purchase_routes: purchase_routes
      }
    end

    private

    def purchase_routes
      @item.item_unlocks.of_type("money").order(:loyalty_level).map do |row|
        {
          trader: row.trader_name.presence || row.trader&.name,
          loyalty_level: row.loyalty_level,
          via_task: row.task&.name
        }
      end
    end
  end
end
