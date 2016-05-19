module PaperTrail
  module AttributeSerializers
    # Included into model if AR version is < 4.2. Backport Rails 4.2 and later's
    # `type_for_attribute` so we can build on a common interface.
    module LegacyActiveRecordShim
      # An attribute which needs no processing. It is part of our backport (shim)
      # of rails 4.2's attribute API. See `type_for_attribute` below.
      class NoOpAttribute
        def type_cast_for_database(value)
          value
        end

        def type_cast_from_database(data)
          data
        end
      end
      NO_OP_ATTRIBUTE = NoOpAttribute.new

      # An attribute which requires manual (de)serialization to/from what we get
      # from the database. It is part of our backport (shim) of rails 4.2's
      # attribute API. See `type_for_attribute` below.
      class SerializedAttribute
        def initialize(coder)
          @coder = coder.respond_to?(:dump) ? coder : PaperTrail.serializer
        end

        def type_cast_for_database(value)
          @coder.dump(value)
        end

        def type_cast_from_database(data)
          @coder.load(data)
        end
      end

      def type_for_attribute(attr_name)
        serialized_attribute_types[attr_name.to_s] || NO_OP_ATTRIBUTE
      end

      def serialized_attribute_types
        @attribute_types ||= Hash[serialized_attributes.map do |attr_name, coder|
          [attr_name, SerializedAttribute.new(coder)]
        end]
      end
      private :serialized_attribute_types
    end
  end
end
