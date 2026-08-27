module Tarkov
  module Syncers
    class Base
      def initialize(client: nil)
        @client = client
      end

      private

      attr_reader :client

      def upsert!(record, attributes)
        record.assign_attributes(attributes)
        record.save!
        record
      end

      def extract_item_tid(value)
        return value unless value.is_a?(Hash)

        value["id"] || value["item"]
      end
    end
  end
end
