# frozen_string_literal: true

module PaperTrail
  module TypeSerializers
    # Provides an alternative method of serialization
    # and deserialization of PostgreSQL array columns.
    class PostgresArraySerializer
      def initialize(subtype, delimiter)
        @subtype = subtype
        @delimiter = delimiter
      end

      def serialize(array)
        array
      end

      def deserialize(array)
        case array
        # Needed for legacy data. If serialized array is a string
        # then it was serialized with Rails < 5.0.2.
        when ::String then deserialize_with_ar(array)
        else array
        end
      end

      private

      def deserialize_with_ar(array)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.
          new(@subtype, @delimiter).
          deserialize(array)
      end
    end
  end
end
