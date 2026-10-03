# frozen_string_literal: true

module PaperTrail
  module TypeSerializers
    # Provides an alternative method of serialization
    # and deserialization of date related columns.
    class DateTimeSerializer
      def initialize(original_type)
        @original_type = original_type
      end

      def serialize(value)
        value&.to_json
      end

      def deserialize(value)
        @original_type.deserialize(value)
      end
    end
  end
end
