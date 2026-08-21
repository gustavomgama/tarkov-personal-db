module Tarkov
  class ItemUnlockLookup
    def initialize(item)
      @item = item
    end

    def call
      {
        item: @item,
        unlock_paths: UnlockPathResolver.new(@item).resolve,
        offers: offers
      }
    end

    private

    def offers
      @item.trader_items.includes(:trader).order(:min_trader_level).map do |offer|
        {
          trader: offer.trader.name,
          min_trader_level: offer.min_trader_level,
          kind: offer.barter? ? "barter" : "cash"
        }
      end
    end
  end
end
