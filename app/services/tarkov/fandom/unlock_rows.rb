module Tarkov
  module Fandom
    class UnlockRows
      def self.sync!(item, unlock_text)
        return item.item_unlocks.destroy_all if unlock_text.blank?

        task_title = unlock_text[/after completing \w+ task (.+)$/i, 1]
        kept = unlock_text.scan(/([^;,]+?)\s+LL(\d+)/i).map do |trader_title, loyalty|
          row = ItemUnlock.find_or_initialize_by(item: item, trader_title: trader_title.strip)
          row.assign_attributes(loyalty_level: loyalty.to_i, unlocking_task_title: task_title&.strip)
          row.save!
          row
        end
        (item.item_unlocks - kept).each(&:destroy!)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] unlocks for #{item.tid} skipped: #{e.message}")
        []
      end
    end
  end
end
