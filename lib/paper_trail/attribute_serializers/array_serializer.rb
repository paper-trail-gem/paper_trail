module PaperTrail
  module AttributeSerializers
    # :nodoc:
    class ArraySerializer
      def initialize(subtype, delimiter)
        @subtype = subtype
        @delimiter = delimiter
      end

      def serialize(array)
        array
      end

      def deserialize(array)
        case array
        when ::String then deserialize_with_ar(array)
        else array
        end
      end

      def deserialize_with_ar(array)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.
          new(@subtype, @delimiter).
          deserialize(array)
      end
    end
  end
end
