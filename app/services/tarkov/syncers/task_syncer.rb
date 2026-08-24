module Tarkov
  module Syncers
    class TaskSyncer < Base
      def call
        payload = client.tasks
        tasks = (payload["tasks"] || {})
        records = tasks.each_value.filter_map { |attrs| sync_task(attrs) }
        tasks.each_value { |attrs| sync_task_requirements(attrs) }
        sync_offer_unlocks(tasks)
        records.size
      end

      private

      def sync_task(attrs)
        upsert!(find_task(attrs), task_attributes(attrs))
        true
      rescue ActiveRecord::RecordInvalid, KeyError => e
        warn "task #{attrs['id']} skipped: #{e.message}"
        nil
      end

      def find_task(attrs)
        Task.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def task_attributes(attrs)
        {
          name: attrs["name"],
          trader: attrs["trader"].present? ? Trader.find_by(tid: attrs["trader"]) : nil,
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
          task = Task.find_by(tid: attrs["id"])
          next unless task

          Array(attrs.dig("finishRewards", "offerUnlock")).each do |offer|
            sync_offer_unlock(task, offer)
          end
        end
      end

      def sync_offer_unlock(task, offer)
        item = Item.find_by(tid: extract_item_tid(offer["item"]))
        return unless item

        trader = Trader.find_by(tid: offer["trader"])
        row = ItemUnlock.where(item_id: item.id, trader_id: trader&.id, task_id: task.id,
                              source: "dev").of_type("money").first ||
              ItemUnlock.new(item_id: item.id, item_name: item.name, task_id: task.id,
                            trader_id: trader&.id, source: "dev", unlock_types: [ "money" ])
        upsert!(row, { item_name: item.name, trader_name: trader&.name,
                       loyalty_level: offer["level"] })
        item.update!(require_unlock: true)
      rescue ActiveRecord::RecordInvalid => e
        warn "offer unlock skipped for #{task.tid}: #{e.message}"
      end

      def extract_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end

      def sync_task_requirements(attrs)
        task = Task.find_by(tid: attrs["id"])
        return unless task

        kept = Array(attrs["taskRequirements"]).filter_map do |requirement|
          required = Task.find_by(tid: requirement["task"])
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
