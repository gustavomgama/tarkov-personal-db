module Tarkov
  module Syncers
    class TaskSyncer < Base
      ITEM_OBJECTIVE_TYPES = %w[findItem giveItem plantItem buildWeapon].freeze
      QUEST_ITEM_OBJECTIVE_TYPES = %w[findQuestItem plantQuestItem handoverQuestItem].freeze

      def call
        payload = client.tasks
        tasks = (payload["tasks"] || {})
        quest_items = (payload["questItems"] || {})
        records = tasks.each_value.filter_map { |attrs| sync_task(attrs, quest_items) }
        tasks.each_value { |attrs| sync_task_requirements(attrs) }
        records.size
      end

      private

      def sync_task(attrs, quest_items = {})
        task = upsert!(find_task(attrs), task_attributes(attrs))
        sync_objectives(task, attrs["objectives"], quest_items)
        task
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
          faction_name: attrs["factionName"],
          wiki_link: attrs["wikiLink"]
        }
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

      def sync_objectives(task, objectives, quest_items = {})
        Array(objectives).each do |objective|
          if QUEST_ITEM_OBJECTIVE_TYPES.include?(objective["type"])
            sync_quest_item_objective(task, objective, quest_items)
            next
          end
          next unless objective_type_relevant?(objective)

          item_tids_for(objective).each do |item_tid|
            item = Item.find_by(tid: item_tid)
            unless item
              warn "task #{task.tid} references unknown item #{item_tid}"
              next
            end
            upsert!(find_objective(task, item), objective_attributes(objective))
          end
        end
      end

      def sync_quest_item_objective(task, objective, quest_items)
        tid = extract_quest_item_tid(objective["questItem"])
        attributes = quest_items[tid]
        unless tid && attributes
          warn "task #{task.tid} references unknown quest item #{tid}"
          return
        end

        item = upsert!(Item.find_or_initialize_by(tid: tid), quest_item_attributes(attributes))
        upsert!(find_objective(task, item), objective_attributes(objective))
      end

      def extract_quest_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end

      def quest_item_attributes(attrs)
        {
          name: attrs["name"],
          short_name: attrs["shortName"],
          description: attrs["description"],
          types: [ "questItem" ],
          width: attrs["width"],
          height: attrs["height"],
          icon_link: attrs["iconLink"],
          grid_image_link: attrs["gridImageLink"]
        }
      end

      def find_objective(task, item)
        TaskObjective.find_or_initialize_by(task: task, item: item)
      end

      def objective_attributes(objective)
        {
          count: objective["count"],
          found_in_raid: objective["foundInRaid"] || false
        }
      end

      def objective_type_relevant?(objective)
        ITEM_OBJECTIVE_TYPES.include?(objective["type"])
      end

      def item_tids_for(objective)
        Array(objective["items"]) + ([ objective["item"] ] if objective["item"].present?).to_a
      end

      def warn(message)
        Rails.logger.warn("[tarkov:sync] #{message}")
      end
    end
  end
end
