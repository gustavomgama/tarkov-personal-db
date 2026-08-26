module Tarkov
  module Syncers
    # Content removed from the live game must never linger: tasks and items
    # whose names appear on the fandom "Historical content" list are purged
    # here, after every writer has run. ItemSyncer/TaskSyncer also skip them
    # at write time; this sweep catches rows from older runs.
    class HistoricalPurge < Base
      def call
        removed_tasks = purge_tasks
        removed_items = purge_items
        [ removed_tasks, removed_items ]
      end

      private

      def purge_tasks
        doomed = Task.all.select { |task| historical?(task.name) }
        doomed.each(&:destroy!) # cascades to unlocks + requirements
        doomed.size
      end

      def purge_items
        doomed = Item.all.select { |item| historical?(item.name) }
        doomed.each do |item|
          ItemUnlock.where(item_id: item.id).destroy_all
          item.delete
          Dir[Rails.root.join("public/images/items/#{item.tid}*")].each { |file| File.delete(file) }
        end
        doomed.size
      end

      def historical?(name)
        Tarkov::HistoricalContent.historical?(name)
      end
    end
  end
end
