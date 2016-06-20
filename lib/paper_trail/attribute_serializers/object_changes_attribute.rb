require "paper_trail/attribute_serializers/cast_attribute_serializer"

module PaperTrail
  module AttributeSerializers
    # Serialize or deserialize the `version.object_changes` column.
    class ObjectChangesAttribute
      def initialize(item_class)
        @item_class = item_class
      end

      def serialize(changes)
        alter(changes, :serialize)
      end

      def deserialize(changes)
        alter(changes, :deserialize)
      end

      private

      # Modifies `changes` in place.
      # TODO: Return a new hash instead.
      def alter(changes, serialization_method)
        # Don't serialize before values before inserting into columns of type
        # `JSON` on `PostgreSQL` databases.
        return changes if object_changes_col_is_json?

        serializer = CastAttributeSerializer.new(@item_class)
        changes.clone.each do |key, change|
          # `change` is an Array with two elements, representing before and after.
          changes[key] = Array(change).map do |value|
            serializer.send(serialization_method, key, value)
          end
        end
      end

      def object_changes_col_is_json?
        @item_class.paper_trail.version_class.object_changes_col_is_json?
      end
    end
  end
end
