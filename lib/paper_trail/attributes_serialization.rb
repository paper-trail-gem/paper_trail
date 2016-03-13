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

    class AbstractSerializer
      def initialize(klass)
        @klass = klass
      end

      private

      def apply_serialization(method, attr, val)
        @klass.type_for_attribute(attr).send(method, val)
      end
    end

    if ::ActiveRecord::VERSION::MAJOR >= 5
      class CastedAttributeSerializer < AbstractSerializer
        def serialize(attr, val)
          apply_serialization(:serialize, attr, val)
        end

        def deserialize(attr, val)
          apply_serialization(:deserialize, attr, val)
        end
      end
    else
      class CastedAttributeSerializer < AbstractSerializer
        def serialize(attr, val)
          val = defined_enums[attr][val] if defined_enums[attr]
          apply_serialization(:type_cast_for_database, attr, val)
        end

        def deserialize(attr, val)
          val = apply_serialization(:type_cast_from_database, attr, val)

          if defined_enums[attr]
            defined_enums[attr].key(val)
          else
            val
          end
        end

        private

        def defined_enums
          @defined_enums ||= (@klass.respond_to?(:defined_enums) ? @klass.defined_enums : {})
        end
      end
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
      alter_attributes_for_paper_trail!(:serialize, attributes)
    end

    def unserialize_attributes_for_paper_trail!(attributes)
      alter_attributes_for_paper_trail!(:deserialize, attributes)
    end

    def alter_attributes_for_paper_trail!(serialization_method, attributes)
      # Don't serialize before values before inserting into columns of type
      # `JSON` on `PostgreSQL` databases.
      return attributes if paper_trail_version_class.object_col_is_json?

      serializer = CastedAttributeSerializer.new(self)
      attributes.each do |key, value|
        attributes[key] = serializer.send(serialization_method, key, value)
      end
    end

    # Used for Version#object_changes attribute.
    def serialize_attribute_changes_for_paper_trail!(changes)
      alter_attribute_changes_for_paper_trail!(:serialize, changes)
    end

    def unserialize_attribute_changes_for_paper_trail!(changes)
      alter_attribute_changes_for_paper_trail!(:deserialize, changes)
    end

    def alter_attribute_changes_for_paper_trail!(serialization_method, changes)
      # Don't serialize before values before inserting into columns of type
      # `JSON` on `PostgreSQL` databases.
      return changes if paper_trail_version_class.object_changes_col_is_json?

      serializer = CastedAttributeSerializer.new(self)
      changes.clone.each do |key, change|
        changes[key] = Array(change).map do |value|
          serializer.send(serialization_method, key, value)
        end
      end
    end
  end
end
