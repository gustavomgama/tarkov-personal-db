module Tarkov
  module Syncers
    class BarterSyncer < Base
      # Barters become barter-type ItemUnlock rows and set item.barter.
      # Identity is [item, trader, task, loyalty] so a trader offering the same
      # item at several loyalty levels keeps one row per level.

      def call
        sync_cash_offers
        barters = client.barters
        kept = []
        barters.each do |barter|
          row = sync_barter(barter)
          kept << row if row
        end

        stale_scope = ItemUnlock.where(source: "dev").of_type("barter")
        stale_scope = stale_scope.where(item_id: kept.map(&:item_id).uniq) if kept.any?
        (kept.any? ? stale_scope : ItemUnlock.of_type("barter")).reject { |row| kept.include?(row) }
                                                               .each(&:destroy!)
        kept.size
      end

      # Structured money routes from the items payload (buyFromTrader).
      # Additive only - wiki-derived money rows are never deleted here.
      def sync_cash_offers
        (client.items.fetch("items", {})).each_value do |attrs|
          item = Item.find_by(tid: attrs["id"])
          next unless item

          Array(attrs["buyFromTrader"]).each do |offer|
            sync_money_offer(item, offer)
          end
        end
      end

      def sync_money_offer(item, offer)
        trader = Trader.find_by(tid: offer["trader"])
        task_id = Task.find_by(tid: offer["taskUnlock"])&.id
        loyalty = offer["minTraderLevel"]
        row = ItemUnlock.where(item_id: item.id, trader_id: trader&.id,
                               task_id: task_id, loyalty_level: loyalty,
                               source: "dev").of_type("money").first ||
              ItemUnlock.new(
                item_id: item.id, item_name: item.name,
                trader_id: trader&.id, trader_name: trader&.name,
                task_id: task_id, loyalty_level: loyalty,
                unlock_types: [ "money" ], source: "dev"
              )
        upsert!(row, { item_name: item.name })
        item.update!(require_unlock: true) if task_id
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] money offer skipped for #{item.tid}: #{e.message}")
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
                             source: "dev", item_name: item.name)
        upsert!(row, { item_name: item.name, source: "dev",
                       trader_id: trader.id, trader_name: trader.name })
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
