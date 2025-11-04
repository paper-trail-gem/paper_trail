# frozen_string_literal: true

require "paper_trail/attribute_serializers/cast_attribute_serializer"
require "paper_trail/type_serializers/postgres_range_serializer"

module PaperTrail
  module AttributeSerializers
    # Serialize or deserialize the `version.object` column.
    class ObjectAttribute
      def initialize(model_class)
        @model_class = model_class

        # ActiveRecord since 7.0 has a built-in encryption mechanism
        @encrypted_attributes = @model_class.encrypted_attributes&.map(&:to_s)
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
        # Don't serialize non-encrypted before values before inserting into columns of type
        # `JSON` on `PostgreSQL` databases.
        attributes_to_serialize = attributes_to_serialize(attributes)

        return attributes if attributes_to_serialize.blank?

        serializer = CastAttributeSerializer.new(@model_class)
        attributes_to_serialize.each do |key, value|
          attributes[key] = serializer.send(serialization_method, key, value)
        end

        attributes
      end

      # Don't de/serialize non-encrypted before values before inserting into columns of type
      # `JSON` on `PostgreSQL` databases; Unless it's a special type like a range.
      def attributes_to_serialize(attributes)
        encrypted_to_serialize = if object_col_is_json?
                                   attributes.slice(*@encrypted_attributes)
                                 else
                                   attributes
                                 end

        columns_to_serialize = attributes.select { |column, _|
          TypeSerializers::PostgresRangeSerializer.range_type?(
            @model_class.columns_hash[column]&.type
          )
        }

        encrypted_to_serialize.merge(columns_to_serialize)
      end

      def object_col_is_json?
        @model_class.paper_trail.version_class.object_col_is_json?
      end
    end
  end
end
