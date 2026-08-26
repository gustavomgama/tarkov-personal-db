module Tarkov
  module Syncers
    class TraderSyncer < Base
      def call
        traders = client.traders
        traders.each_value.sum { |attrs| sync_trader(attrs) ? 1 : 0 }
      end

      private

      def sync_trader(attrs)
        trader = upsert!(find_trader(attrs), trader_attributes(attrs))
        sync_loyalty_levels(trader, attrs["levels"])
        true
      end

      def find_trader(attrs)
        Trader.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def trader_attributes(attrs)
        {
          name: client.localizations.trader_nickname(attrs.fetch("id")) || attrs["name"],
          slug: attrs["normalizedName"],
          image_url: attrs["imageLink"],
          reset_time: parse_time(attrs["resetTime"])
        }
      end

      def sync_loyalty_levels(trader, levels)
        kept = Array(levels).map do |level_attrs|
          record = trader.trader_loyalty_levels.find_or_initialize_by(level: level_attrs.fetch("level"))
          upsert!(record, {
            required_player_level: level_attrs["requiredPlayerLevel"],
            required_reputation: level_attrs["requiredReputation"]
          })
        end
        (trader.trader_loyalty_levels - kept).each(&:destroy!)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] loyalty levels for #{trader.tid} skipped: #{e.message}")
      end

      def parse_time(value)
        Time.zone.parse(value) if value.present?
      rescue ArgumentError
        nil
      end
    end
  end
end
