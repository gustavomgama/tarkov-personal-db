module Tarkov
  module Fandom
    class UnlockRows
      UNKNOWN_MARKERS = %w[??? ??].freeze

      def self.sync!(item, unlock_text)
        return item.item_unlocks.destroy_all if unlock_text.blank?

        task_title = task_title_from(unlock_text)
        kept = unlock_text.scan(/([^;,]+?)\s+LL(\d+)/i).map do |trader_title, loyalty|
          row = ItemUnlock.find_or_initialize_by(item: item, trader_title: trader_title.strip)
          row.assign_attributes(loyalty_level: loyalty.to_i, unlocking_task_title: task_title)
          row.save!
          row
        end
        (item.item_unlocks - kept).each(&:destroy!)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] unlocks for #{item.tid} skipped: #{e.message}")
        []
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
