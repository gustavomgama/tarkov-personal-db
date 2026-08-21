module Tarkov
  class TaskChainView
    def initialize(task)
      @task = task
    end

    def call
      {
        task: @task,
        requires: walk(@task, :prerequisite_tasks),
        leads_to: walk(@task, :unlocking_tasks)
      }
    end

    private

    def walk(task, direction)
      visited = {}
      queue = [ [ task, 0 ] ]
      until queue.empty?
        current, depth = queue.shift
        current.public_send(direction).each do |next_task|
          next if visited.key?(next_task.id)

          visited[next_task.id] = { task: next_task, depth: depth + 1 }
          queue.push([ next_task, depth + 1 ])
        end
      end
      visited.values.sort_by { |node| [ node[:depth], node[:task].name ] }
    end
  end
end
