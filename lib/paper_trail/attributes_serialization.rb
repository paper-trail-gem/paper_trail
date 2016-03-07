module PaperTrail
  module AttributesSerialization
    class NoOpAttribute
      def type_cast_for_database(value)
        value
      end

      def type_cast_from_database(data)
        data
      end
    end
    NO_OP_ATTRIBUTE = NoOpAttribute.new

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

    SERIALIZE, DESERIALIZE =
      if ::ActiveRecord::VERSION::MAJOR >= 5
        [:serialize, :deserialize]
      else
        [:type_cast_for_database, :type_cast_from_database]
      end

    if ::ActiveRecord::VERSION::STRING < "4.2"
      # Backport Rails 4.2 and later's `type_for_attribute` to build
      # on a common interface.
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

    # Used for `Version#object` attribute.
    def serialize_attributes_for_paper_trail!(attributes)
      alter_attributes_for_paper_trail!(SERIALIZE, attributes)
    end

    def unserialize_attributes_for_paper_trail!(attributes)
      alter_attributes_for_paper_trail!(DESERIALIZE, attributes)
    end

    def alter_attributes_for_paper_trail!(serializer, attributes)
      # Don't serialize before values before inserting into columns of type
      # `JSON` on `PostgreSQL` databases.
      return attributes if paper_trail_version_class.object_col_is_json?

      attributes.each do |key, value|
        attributes[key] = type_for_attribute(key).send(serializer, value)
      end
    end

    # Used for Version#object_changes attribute.
    def serialize_attribute_changes_for_paper_trail!(changes)
      alter_attribute_changes_for_paper_trail!(SERIALIZE, changes)
    end

    def unserialize_attribute_changes_for_paper_trail!(changes)
      alter_attribute_changes_for_paper_trail!(DESERIALIZE, changes)
    end

    def alter_attribute_changes_for_paper_trail!(serializer, changes)
      # Don't serialize before values before inserting into columns of type
      # `JSON` on `PostgreSQL` databases.
      return changes if paper_trail_version_class.object_changes_col_is_json?

      changes.clone.each do |key, change|
        type = type_for_attribute(key)
        changes[key] = Array(change).map { |value| type.send(serializer, value) }
      end
    end
  end
end
