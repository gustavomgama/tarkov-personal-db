module Tarkov
  module Syncers
    class BarterSyncer < Base
      # Barters become barter-type ItemUnlock rows and set item.barter.
      # Identity is [item, trader, task, loyalty] so a trader offering the same
      # item at several loyalty levels keeps one row per level.

      def call
        preload_lookups
        sync_cash_offers
        barters = client.barters
        return 0 if barters.empty?

        kept = []
        barters.each do |barter|
          row = sync_barter(barter)
          kept << row if row
        end

        if kept.any?
          # Cleanup only touches dev rows for items still present upstream; an
          # empty/failed response must never wipe stored unlocks.
          live_item_ids = kept.map(&:item_id).uniq
          stale = ItemUnlock.where(source: "dev", item_id: live_item_ids)
                            .of_type("barter")
                            .or(ItemUnlock.where(source: "dev", item_id: live_item_ids)
                                          .of_type("money").where(currency: "GP"))
                            .where.not(id: kept.map(&:id))
          stale.each(&:destroy!)
        end
        refresh_flags_batch(kept)
        kept.size
      end

      private

      # Preset families collapse onto their canonical item (see PresetCollapse).
      def items_payload
        @items_payload ||= client.items.fetch("items", {})
      end

      def collapse
        @collapse ||= Tarkov::PresetCollapse.new(items_payload.values)
      end

      def preload_lookups
        @traders_by_tid = Trader.all.index_by(&:tid)
        @tasks_by_tid = Task.all.index_by(&:tid)
        @items_by_tid = Item.all.index_by(&:tid)
      end

      def trader_for(tid)
        @traders_by_tid[tid]
      end

      def task_id_for(tid)
        @tasks_by_tid[tid]&.id
      end

      def item_for_tid(tid)
        @items_by_tid[tid]
      end

      # Structured money routes from the items payload (buyFromTrader).
      # Additive only - wiki-derived money rows are never deleted here.
      def sync_cash_offers
        items_payload.each_value do |attrs|
          canonical_tid = collapse.resolve(attrs["id"])
          item = Item.find_canonical(canonical_tid)
          next unless item

          Array(attrs["buyFromTrader"]).each do |offer|
            sync_money_offer(item, offer, variant_label_for(attrs, item))
          end
        end
      end

      def sync_money_offer(item, offer, variant = nil)
        trader = trader_for(offer["trader"])
        tid = offer["taskUnlock"]
        task_id = tid ? task_id_for(tid) : nil
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
        upsert!(row, { item_name: item.name, source_variant: variant })
        item.update!(require_unlock: true) if task_id
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] money offer skipped for #{item.tid}: #{e.message}")
      end

      def sync_barter(barter)
        raw_tid = extract_item_tid(barter["offeredItem"])
        offered_tid = collapse.resolve(raw_tid)
        trader = trader_for(barter["trader"])
        item = offered_tid && Item.find_canonical(offered_tid)
        return nil unless trader && item

        variant = variant_label_for(items_payload[raw_tid], item)
        loyalty = barter["minTraderLevel"] || barter["level"]
        task_id = task_id_for(barter["taskUnlock"])
        row = ItemUnlock.where(item_id: item.id, trader_id: trader.id, task_id: task_id,
                               loyalty_level: loyalty).of_type("barter").first ||
              ItemUnlock.new(item_id: item.id, trader_id: trader.id, trader_name: trader.name,
                             task_id: task_id, loyalty_level: loyalty, unlock_types: [ "barter" ],
                             source: "dev", item_name: item.name)
        ingredients = required_items_for(barter)
        gp_payment = gp_payment?(ingredients)
        upsert!(row, {
          item_name: item.name, source: "dev",
          trader_id: trader.id, trader_name: trader.name,
          required_items: ingredients,
          source_variant: variant,
          unlock_types: [ gp_payment ? "money" : "barter" ],
          currency: gp_payment ? "GP" : nil
        })
        row
      end

      # Paying exclusively with GP coins is a purchase in Arena currency,
      # not a barter - Ref-only items surface separately in the UI.
      def gp_payment?(ingredients)
        ingredients.any? && ingredients.all? { |i| i["tid"] == ApplicationHelper::GP_COIN_TID }
      end

      # Batch-refresh acquisition flags for all items touched in this run.
      def refresh_flags_batch(kept)
        return if kept.empty?

        item_ids = kept.map(&:item_id).uniq
        gp_item_ids = ItemUnlock.where(item_id: item_ids, currency: "GP").pluck(:item_id)
        barter_item_ids = ItemUnlock.where(item_id: item_ids).of_type("barter").pluck(:item_id)
        all_affected = (gp_item_ids | barter_item_ids).uniq
        return if all_affected.empty?

        Item.where(id: all_affected).find_each do |item|
          item.update_columns(
            ref_gp: gp_item_ids.include?(item.id),
            barter: barter_item_ids.include?(item.id)
          )
        end
      end

      # When the offer targeted a non-default variant of a collapsed family,
      # remember its display name so routes can describe it.
      def variant_label_for(attrs, canonical_item)
        return nil unless attrs.is_a?(Hash)
        return nil if attrs["id"] == canonical_item.tid

        tid = attrs["id"]
        names = client.localizations
        names.item_short_name(tid).presence || names.item_name(tid).presence
      end

      # Ingredient list for the visual recipe card: [{tid, name, icon_link, count}].
      # Some barter-only ingredients (CPU fans, gyro-tachometers...) are absent
      # from the items payload; their names still resolve via localizations.
      def required_items_for(barter)
        Array(barter["requiredItems"]).filter_map do |req|
          raw_tid = extract_item_tid(req["item"])
          tid = ItemAlias.resolve(collapse.resolve(raw_tid))
          next unless tid

          ingredient = item_for_tid(tid) || Item.find_by(tid: tid)
          {
            "tid" => tid,
            "name" => ingredient&.name || client.localizations.item_name(raw_tid) || tid,
            "icon_link" => ingredient&.icon_link,
            "count" => req["count"] || 1
          }
        end
      end

      def extract_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end
    end
  end
end
