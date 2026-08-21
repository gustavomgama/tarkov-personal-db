module Tarkov
  class UnlockPathResolver
    Entry = Data.define(:unlock, :task, :prerequisites, :root_quests, :required_player_level)

    def initialize(item)
      @item = item
    end

    def resolve
      @item.item_unlocks.order(:trader_title).map { |unlock| entry_for(unlock) }
    end

    private

    def entry_for(unlock)
      task = Task.find_by_wiki_title(unlock.unlocking_task_title.to_s)
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
