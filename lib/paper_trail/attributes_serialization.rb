module PaperTrail
  # "Serialization" here refers to the preparation of data for insertion into a
  # database, particularly the `object` and `object_changes` columns in the
  # `versions` table.
  #
  # Likewise, "deserialization" refers to any processing of data after they
  # have been read from the database, for example preparing the result of
  # `VersionConcern#changeset`.
  module AttributesSerialization
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

    # The `AbstractSerializer` (de)serializes model attribute values. For
    # example, the string "1.99" serializes into the integer `1` when assigned
    # to an attribute of type `ActiveRecord::Type::Integer`.
    #
    # This implementation depends on the `type_for_attribute` method, which was
    # introduced in rails 4.2. In older versions of rails, we shim this method
    # below.
    #
    # At runtime, the `AbstractSerializer` has only one child class, the
    # `CastedAttributeSerializer`, whose implementation varies depending on the
    # version of ActiveRecord.
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
      # This implementation uses AR 5's `serialize` and `deserialize`.
      class CastedAttributeSerializer < AbstractSerializer
        def serialize(attr, val)
          apply_serialization(:serialize, attr, val)
        end

        def deserialize(attr, val)
          apply_serialization(:deserialize, attr, val)
        end
      end
    else
      # This implementation uses AR 4.2's `type_cast_for_database`. For
      # versions of AR < 4.2 we provide an implementation of
      # `type_cast_for_database` in our shim attribute type classes,
      # `NoOpAttribute` and `SerializedAttribute`.
      class CastedAttributeSerializer < AbstractSerializer
        def serialize(attr, val)
          if defined_enums[attr].present? && val.is_a?(::String)
            val = defined_enums[attr][val]
          end
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

        # Returns a Hash that maps column names to hashes, which in turn
        # map strings to integers. For example, the PostWithStatus model
        # in our test suite has the following:
        # {"status"=>{"draft"=>0, "published"=>1, "archived"=>2}}
        def defined_enums
          @defined_enums ||= (@klass.respond_to?(:defined_enums) ? @klass.defined_enums : {})
        end
      end
    end

    # Backport Rails 4.2 and later's `type_for_attribute` so we can build
    # on a common interface.
    if ::ActiveRecord::VERSION::STRING < "4.2"
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
        # `change` is an Array with two elements, representing before and after.
        changes[key] = Array(change).map do |value|
          serializer.send(serialization_method, key, value)
        end
      end
    end
  end
end
