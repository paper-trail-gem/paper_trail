require "paper_trail/attribute_serializers/cast_attribute_serializer"

module PaperTrail
  module AttributeSerializers
    # Serialize or deserialize the `version.object` column.
    class ObjectAttribute
      def initialize(model_class)
        @model_class = model_class
      end

      def serialize(attributes)
        alter(attributes, :serialize)
      end

      def deserialize(attributes)
        alter(attributes, :deserialize)
      end

      private

      # Modifies `attributes` in place.
      # TODO: Return a new hash instead.
      def alter(attributes, serialization_method)
        # Don't serialize before values before inserting into columns of type
        # `JSON` on `PostgreSQL` databases.
        return attributes if object_col_is_json?

        serializer = CastAttributeSerializer.new(@model_class)
        attributes.each do |key, value|
          attributes[key] = serializer.send(serialization_method, key, value)
        end
      end

      def object_col_is_json?
        @model_class.paper_trail.version_class.object_col_is_json?
      end
    end
  end
end
