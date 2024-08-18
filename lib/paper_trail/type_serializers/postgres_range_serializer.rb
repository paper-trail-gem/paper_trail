# frozen_string_literal: true

module PaperTrail
  module TypeSerializers
    # Provides an alternative method of serialization
    # and deserialization of PostgreSQL range columns.
    class PostgresRangeSerializer
      # @see https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L147-L152
      RANGE_TYPES = %i[
        daterange
        numrange
        tsrange
        tstzrange
        int4range
        int8range
      ].freeze

      def self.range_type?(type)
        RANGE_TYPES.include?(type)
      end

      def initialize(active_record_serializer)
        @active_record_serializer = active_record_serializer
      end

      def serialize(range)
        range
      end

      def deserialize(range)
        range.is_a?(String) ? deserialize_with_ar(range) : range
      end

      private

      def deserialize_with_ar(string)
        return nil if string.blank?

        delimiter = string[/\.{2,3}/]
        range_start, range_end = string.split(delimiter)

        range_start = @active_record_serializer.subtype.cast(range_start)
        range_end   = @active_record_serializer.subtype.cast(range_end)

        Range.new(range_start, range_end, exclude_end: delimiter == "...")
      end
    end
  end
end
