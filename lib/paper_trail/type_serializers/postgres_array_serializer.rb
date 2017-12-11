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
        return serialize_with_ar(array) if active_record_pre_502?
        array
      end

      def deserialize(array)
        return deserialize_with_ar(array) if active_record_pre_502?

        case array
        # Needed for legacy reasons. If serialized array is a string
        # then it was serialized with Rails < 5.0.2.
        when ::String then deserialize_with_ar(array)
        else array
        end
      end

      private

      def active_record_pre_502?
        ::ActiveRecord::VERSION::MAJOR < 5 ||
          (::ActiveRecord::VERSION::MINOR.zero? && ::ActiveRecord::VERSION::TINY < 2)
      end

      def serialize_with_ar(array)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.
          new(@subtype, @delimiter).
          serialize(array)
      end

      def deserialize_with_ar(array)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.
          new(@subtype, @delimiter).
          deserialize(array)
      end
    end
  end
end
