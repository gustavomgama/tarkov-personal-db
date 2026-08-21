module Tarkov
  module Syncers
    class TaskSyncer < Base
      ITEM_OBJECTIVE_TYPES = %w[findItem giveItem plantItem buildWeapon].freeze

      def call
        tasks = (client.tasks["tasks"] || {})
        records = tasks.each_value.filter_map { |attrs| sync_task(attrs) }
        tasks.each_value { |attrs| sync_task_requirements(attrs) }
        records.size
      end

      private

      def sync_task(attrs)
        task = upsert!(find_task(attrs), task_attributes(attrs))
        sync_objectives(task, attrs["objectives"])
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

      def sync_objectives(task, objectives)
        Array(objectives).each do |objective|
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
