module Tarkov
  module Syncers
    class TraderPurge < Base
      KEEP = %w[BTR\ Driver Fence Jaeger Lightkeeper Mechanic Peacekeeper Prapor Ragman Ref Skier Therapist].freeze

      # Event traders have no wiki pages and no place in an unlock navigator.
      def call
        removed = 0
        Trader.find_each do |trader|
          next if KEEP.include?(trader.name)

          ItemUnlock.where(trader_id: trader.id).delete_all
          trader.destroy!
          removed += 1
        end
        # Rows whose trader could never be resolved to a kept one.
        removed += ItemUnlock.of_type(%w[money barter]).where(trader_id: nil)
                             .where.not(trader_name: KEEP).delete_all
        removed
      end
    end
  end
end
