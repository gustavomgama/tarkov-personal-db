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
    end
  end
end
