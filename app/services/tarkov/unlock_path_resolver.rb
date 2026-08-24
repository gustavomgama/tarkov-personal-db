module Tarkov
  class UnlockPathResolver
    Entry = Data.define(:unlock, :task, :prerequisites, :root_quests, :required_player_level)

    def initialize(item)
      @item = item
    end

    # One de-duplicated, dependency-ordered task list across all routes (KISS):
    # every task involved in unlocking the item, roots first, cycles safe.
    def self.merged_chain(entries)
      tasks = entries.flat_map { |entry|
        entry.prerequisites.map { |node| node[:task] } + [ entry.task ]
      }.compact.uniq
      return [] if tasks.empty?

      ids = tasks.map(&:id).to_set
      dependencies = tasks.to_h do |task|
        [ task.id, task.prerequisite_tasks.select { |pre| ids.include?(pre.id) }.map(&:id).to_set ]
      end

      ordered = []
      done = Set.new
      remaining = tasks.sort_by { |task| [ task.min_player_level.to_i, task.name ] }
      until remaining.empty?
        ready = remaining.select { |task| dependencies[task.id] <= done }
        ready = [ remaining.first ] if ready.empty? # cycle guard

        ready.each { |task| ordered << task }
        done.merge(ready.map(&:id))
        remaining -= ready
      end
      ordered
    end

    def resolve
      @item.item_unlocks.order(:trader_name).map { |unlock| entry_for(unlock) }
    end

    private

    def entry_for(unlock)
      task = unlock.task
      return Entry.new(unlock: unlock, task: nil, prerequisites: [], root_quests: [], required_player_level: nil) unless task

      prerequisites = collect_prerequisites(task)
      all_nodes = prerequisites + [ { task: task } ]
      roots = all_nodes.select { |node| node[:task].prerequisite_tasks.empty? }
      Entry.new(
        unlock: unlock,
        task: task,
        prerequisites: prerequisites,
        root_quests: roots,
        required_player_level: all_nodes.filter_map { |node| node[:task].min_player_level }.max
      )
    end

    def collect_prerequisites(task)
      visited = {}
      queue = [ [ task, 0 ] ]
      until queue.empty?
        current, depth = queue.shift
        current.prerequisite_tasks.each do |required|
          next if visited.key?(required.id)

          visited[required.id] = { task: required, depth: depth + 1 }
          queue.push([ required, depth + 1 ])
        end
      end
      visited.values.sort_by { |node| [ node[:depth], node[:task].name ] }
    end
  end
end
