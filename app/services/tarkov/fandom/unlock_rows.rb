module Tarkov
  module Fandom
    class UnlockRows
      UNKNOWN_MARKERS = %w[??? ??].freeze

      # Wiki trader lines are purchase ("money") unlocks.
      def self.sync!(item, unlock_text)
        return item.item_unlocks.where(source: "wiki").of_type("money").destroy_all if unlock_text.blank?

        task = Task.find_by_wiki_title(task_title_from(unlock_text).to_s)
        # A trailing "after completing his task X" phrase governs every listed
        # route; a leading title only governs the first one.
        task_for_all = trailing_clause(unlock_text).present?
        kept = unlock_text.scan(/([^;,]+?)\s+LL(\d+)/i).each_with_index.map do |(trader_name, loyalty), index|
          row_task = task if task && (task_for_all || index.zero?)
          row = find_row(item, trader_name.strip, row_task)
          row.assign_attributes(
            item_name: item.name,
            loyalty_level: loyalty.to_i,
            unlock_types: [ "money" ]
          )
          row.save!
          item.update!(require_unlock: true) if row_task
          row
        end
        stale = item.item_unlocks.where(source: "wiki").of_type("money").reject { |row| kept.include?(row) }
        stale.each(&:destroy!)
        kept
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] unlocks for #{item.tid} skipped: #{e.message}")
        []
      end

      def self.find_row(item, trader_name, task)
        scope = ItemUnlock.where(item: item, trader_name: trader_name, source: "wiki").of_type("money")
        scope = scope.where(task_id: task&.id)
        scope.first || ItemUnlock.new(
          item: item,
          source: "wiki",
          trader_name: trader_name,
          trader_id: trader_for(trader_name)&.id,
          task_id: task&.id
        )
      end

      def self.trader_for(name)
        Trader.find_by(name: name)
      end

      def self.task_title_from(text)
        trailing_clause(text) || leading_segment(text)
      end

      # "...after completing his task [[The Cleaner]]"
      def self.trailing_clause(text)
        text[/after completing \w+ task ([^;,]+)/i, 1]&.strip
      end

      # "Kings of the Rooftops; Jaeger LL3: OV variant"
      def self.leading_segment(text)
        first = text.split(";").first.to_s.strip
        return nil if first.empty?
        return nil if first.match?(/LL\s*\d/i)
        return nil if UNKNOWN_MARKERS.include?(first)
        return nil if first.include?(":")

        first
      end
    end
  end
end
