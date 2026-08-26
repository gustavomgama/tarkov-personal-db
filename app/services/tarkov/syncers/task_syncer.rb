module Tarkov
  module Syncers
    class TaskSyncer < Base
      def call
        payload = client.tasks
        tasks = (payload["tasks"] || {}).reject { |_, attrs| historical?(attrs) }
        preload_lookups
        records = tasks.each_value.filter_map { |attrs| sync_task(attrs) }
        tasks.each_value { |attrs| sync_task_requirements(attrs) }
        sync_offer_unlocks(tasks)
        sync_reward_items(tasks)
        records.size
      end

      private

      def preload_lookups
        @tasks_by_tid = Task.all.index_by(&:tid)
        @traders_by_tid = Trader.all.index_by(&:tid)
      end

      def find_task(attrs)
        tid = attrs.fetch("id")
        @tasks_by_tid[tid] ||= Task.find_or_initialize_by(tid: tid)
      end

      def sync_task(attrs)
        upsert!(find_task(attrs), task_attributes(attrs))
        true
      rescue ActiveRecord::RecordInvalid, KeyError => e
        warn "task #{attrs['id']} skipped: #{e.message}"
        nil
      end

      def task_attributes(attrs)
        {
          name: client.localizations.task_name(attrs.fetch("id")) || attrs["name"],
          slug: attrs["normalizedName"],
          trader: attrs["trader"].present? ? @traders_by_tid[attrs["trader"]] : nil,
          min_player_level: attrs["minPlayerLevel"],
          kappa_required: attrs["kappaRequired"] || false,
          lightkeeper_required: attrs["lightkeeperRequired"] || false,
          wiki_link: attrs["wikiLink"]
        }
      end

      # finishRewards.offerUnlock = "completing this task lets you buy X" -
      # structured money routes straight from the API.
      def sync_offer_unlocks(tasks)
        tasks.each_value do |attrs|
          task = @tasks_by_tid[attrs["id"]]
          next unless task

          Array(attrs.dig("finishRewards", "offerUnlock")).each do |offer|
            sync_offer_unlock(task, offer)
          end
        end
      end

      def sync_offer_unlock(task, offer)
        raw_tid = extract_item_tid(offer["item"])
        item = Item.find_canonical(raw_tid)
        return unless item

        trader = @traders_by_tid[offer["trader"]]
        row = ItemUnlock.where(item_id: item.id, trader_id: trader&.id, task_id: task.id,
                              source: "dev").of_type("money").first ||
              ItemUnlock.new(item_id: item.id, item_name: item.name, task_id: task.id,
                            trader_id: trader&.id, source: "dev", unlock_types: [ "money" ])
        upsert!(row, { item_name: item.name, trader_name: trader&.name,
                       loyalty_level: offer["level"],
                       source_variant: variant_label_for(raw_tid, item) })
        item.update!(require_unlock: true)
      rescue ActiveRecord::RecordInvalid => e
        warn "offer unlock skipped for #{task.tid}: #{e.message}"
      end

      # offerUnlock may target a non-default weapon variant; keep its display
      # name so the route can describe which build it unlocks.
      def variant_label_for(raw_tid, canonical_item)
        return nil if canonical_item.tid == raw_tid

        names = client.localizations
        names.item_short_name(raw_tid).presence || names.item_name(raw_tid).presence
      end

      def historical?(attrs)
        name = client.localizations.task_name(attrs["id"]) || attrs["name"]
        Tarkov::HistoricalContent.historical?(name)
      end

      # finishRewards.items = items handed to the player on completion
      # (e.g. the Kappa secure container). Routes render these as rewards.
      def sync_reward_items(tasks)
        tasks.each_value do |attrs|
          task = @tasks_by_tid[attrs["id"]]
          next unless task

          Array(attrs.dig("finishRewards", "items")).each do |reward|
            sync_reward_item(task, reward)
          end
        end
      end

      def sync_reward_item(task, reward)
        raw_tid = reward.is_a?(Hash) ? extract_item_tid(reward["item"]) : nil
        item = Item.find_canonical(raw_tid) if raw_tid
        return unless item

        row = ItemUnlock.where(item_id: item.id, task_id: task.id, source: "dev")
                        .of_type("reward").first ||
              ItemUnlock.new(item_id: item.id, item_name: item.name, task_id: task.id,
                             source: "dev", unlock_types: [ "reward" ])
        upsert!(row, { item_name: item.name })
      end

      def extract_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end

      def sync_task_requirements(attrs)
        task = @tasks_by_tid[attrs["id"]]
        return unless task

        kept = Array(attrs["taskRequirements"]).filter_map do |requirement|
          required = @tasks_by_tid[requirement["task"]]
          next unless required

          TaskRequirement.find_or_create_by!(task: task, required_task: required)
        end
        (task.task_requirements - kept).each(&:destroy!)
      rescue ActiveRecord::RecordInvalid => e
        warn "task requirements for #{attrs['id']} skipped: #{e.message}"
      end

      def warn(message)
        Rails.logger.warn("[tarkov:sync] #{message}")
      end
    end
  end
end
