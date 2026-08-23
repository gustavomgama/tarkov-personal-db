module Tarkov
  module Syncers
    class BarterSyncer < Base
      # Barters become barter-type ItemUnlock rows and set item.barter.
      # Identity is [item, trader, task, loyalty] so a trader offering the same
      # item at several loyalty levels keeps one row per level.

      def call
        barters = client.barters
        kept = []
        barters.each do |barter|
          row = sync_barter(barter)
          kept << row if row
        end

        stale_scope = ItemUnlock.of_type("barter")
        stale_scope = stale_scope.where(item_id: kept.map(&:item_id).uniq) if kept.any?
        (kept.any? ? stale_scope : ItemUnlock.of_type("barter")).reject { |row| kept.include?(row) }
                                                               .each(&:destroy!)
        kept.size
      end

      private

      def sync_barter(barter)
        offered_tid = extract_item_tid(barter["offeredItem"])
        trader = Trader.find_by(tid: barter["trader"])
        item = offered_tid && Item.find_by(tid: offered_tid)
        return nil unless trader && item

        loyalty = barter["minTraderLevel"] || barter["level"]
        task_id = Task.find_by(tid: barter["taskUnlock"])&.id
        row = ItemUnlock.where(item_id: item.id, trader_id: trader.id, task_id: task_id,
                               loyalty_level: loyalty).of_type("barter").first ||
              ItemUnlock.new(item_id: item.id, trader_id: trader.id, trader_name: trader.name,
                             task_id: task_id, loyalty_level: loyalty, unlock_types: [ "barter" ],
                             item_name: item.name)
        upsert!(row, { item_name: item.name, trader_id: trader.id, trader_name: trader.name })
        item.update!(barter: true)
        row
      end

      def extract_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end
    end
  end
end
