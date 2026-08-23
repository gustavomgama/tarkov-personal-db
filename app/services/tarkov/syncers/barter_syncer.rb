module Tarkov
  module Syncers
    class BarterSyncer < Base
      # Replaces the old TraderItemSyncer: barters become ItemUnlock rows and
      # set the item.barter flag. Cash offers are not present in this API, so
      # price/currency only get set when a currency amount is actually known.

      def call
        barters = client.barters
        barters.sum { |barter| sync_barter(barter) ? 1 : 0 }
      end

      private

      def sync_barter(barter)
        offered_tid = extract_item_tid(barter["offeredItem"])
        trader = Trader.find_by(tid: barter["trader"])
        item = offered_tid && Item.find_by(tid: offered_tid)
        return false unless trader && item

        task = Task.find_by(tid: barter["taskUnlock"])
        row = find_unlock(item, trader, barter)
        upsert!(row, {
          item_name: item.name,
          loyalty_level: barter["minTraderLevel"] || barter["level"],
          unlock_types: [ "barter" ],
          task_id: task&.id
        })
        item.update!(barter: true)
        true
      end

      def find_unlock(item, trader, barter)
        scope = ItemUnlock.where(item: item, trader: trader)
        scope = scope.where(task_id: Task.find_by(tid: barter["taskUnlock"])&.id)
        scope.first || ItemUnlock.new(item: item, trader: trader)
      end

      def extract_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end
    end
  end
end
