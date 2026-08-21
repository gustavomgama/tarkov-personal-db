module Tarkov
  module Syncers
    class TraderItemSyncer < Base
      def call
        barters = client.barters
        barters.sum { |barter| sync_barter(barter) ? 1 : 0 }
      end

      private

      def sync_barter(barter)
        item_tid = extract_item_tid(barter["offeredItem"])
        trader = Trader.find_by(tid: barter["trader"])
        item = item_tid && Item.find_by(tid: item_tid)
        return false unless trader && item

        upsert!(find_trader_item(trader, item), {
          min_trader_level: barter["minTraderLevel"] || barter["level"],
          unlock_task_id: Task.find_by(tid: barter["taskUnlock"])&.id,
          barter: true
        })
        true
      end

      def find_trader_item(trader, item)
        TraderItem.find_or_initialize_by(trader: trader, item: item)
      end

      def extract_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end
    end
  end
end
