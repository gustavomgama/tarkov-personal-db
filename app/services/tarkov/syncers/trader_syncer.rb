module Tarkov
  module Syncers
    class TraderSyncer < Base
      def call
        traders = client.traders
        traders.each_value.sum { |attrs| upsert!(find_trader(attrs), trader_attributes(attrs)) ? 1 : 0 }
      end

      private

      def find_trader(attrs)
        Trader.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def trader_attributes(attrs)
        {
          name: attrs["name"],
          description: attrs["description"],
          currency: attrs["currency"] || "RUB",
          normalized_name: attrs["normalizedName"],
          reset_time: parse_time(attrs["resetTime"])
        }
      end

      def parse_time(value)
        Time.zone.parse(value) if value.present?
      rescue ArgumentError
        nil
      end
    end
  end
end
