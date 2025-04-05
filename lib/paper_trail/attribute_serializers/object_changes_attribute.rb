# frozen_string_literal: true

require "paper_trail/attribute_serializers/cast_attribute_serializer"

module PaperTrail
  module AttributeSerializers
    # Serialize or deserialize the `version.object_changes` column.
    class ObjectChangesAttribute
      def initialize(item_class)
        @item_class = item_class

        # ActiveRecord since 7.0 has a built-in encryption mechanism
        @encrypted_attributes = @item_class.encrypted_attributes&.map(&:to_s)
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
        # Don't serialize non-encrypted before values before inserting into columns of type
        # `JSON` on `PostgreSQL` databases.
        changes_to_serialize =
          object_changes_col_is_json? ? changes.slice(*@encrypted_attributes) : changes.clone
        return changes if changes_to_serialize.blank?

        serializer = CastAttributeSerializer.new(@item_class)
        changes_to_serialize.each do |key, change|
          # `change` is an Array with two elements, representing before and after.
          changes[key] = Array(change).map do |value|
            serializer.send(serialization_method, key, value)
          end
        end

        changes
      end

      def object_changes_col_is_json?
        @item_class.paper_trail.version_class.object_changes_col_is_json?
      end
    end
  end
end
