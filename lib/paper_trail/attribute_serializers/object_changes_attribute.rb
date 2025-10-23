# frozen_string_literal: true

require "paper_trail/attribute_serializers/cast_attribute_serializer"
require "paper_trail/type_serializers/postgres_range_serializer"

module PaperTrail
  module AttributeSerializers
    # Serialize or deserialize the `version.object_changes` column.
    class ObjectChangesAttribute
      def initialize(model_class)
        @model_class = model_class

        # ActiveRecord since 7.0 has a built-in encryption mechanism
        @encrypted_attributes = @model_class.encrypted_attributes&.map(&:to_s)
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
        changes_to_serialize = changes_to_serialize(changes)
        return changes if changes_to_serialize.blank?

        serializer = CastAttributeSerializer.new(@model_class)
        changes_to_serialize.each do |key, change|
          # `change` is an Array with two elements, representing before and after.
          changes[key] = Array(change).map do |value|
            serializer.send(serialization_method, key, value)
          end
        end

        changes
      end

      # Don't de/serialize non-encrypted before values before inserting into columns of type
      # `JSON` on `PostgreSQL` databases; Unless it's a special type like a range.
      def changes_to_serialize(changes)
        encrypted_to_serialize = if object_changes_col_is_json?
                                   changes.slice(*@encrypted_attributes)
                                 else
                                   changes.clone
                                 end

        columns_to_serialize = changes.select { |column, _|
          TypeSerializers::PostgresRangeSerializer.range_type?(
            @model_class.columns_hash[column]&.type
          )
        }

        encrypted_to_serialize.merge(columns_to_serialize)
      end

      def object_changes_col_is_json?
        @model_class.paper_trail.version_class.object_changes_col_is_json?
      end
    end
  end
end
