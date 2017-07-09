require "active_support/json"

module PaperTrail
  module Serializers
    # An alternate serializer for, e.g. `versions.object`.
    module JSON
      E_WHERE_OBJ_CHANGES = <<-STR.squish.freeze
        where_object_changes has a known issue. When reading json from a text
        column, it may return more records than expected. Instead of a warning,
        this method may raise an error in the future. Please join the discussion
        at https://github.com/airblade/paper_trail/issues/803
      STR

      extend self # makes all instance methods become module methods as well

      def load(string)
        ActiveSupport::JSON.decode string
      end

      def dump(object)
        ActiveSupport::JSON.encode object
      end

      # Returns a SQL LIKE condition to be used to match the given field and
      # value in the serialized object.
      def where_object_condition(arel_field, field, value)
        # Convert to JSON to handle strings and nulls correctly.
        json_value = value.to_json

        # If the value is a number, we need to ensure that we find the next
        # character too, which is either `,` or `}`, to ensure that searching
        # for the value 12 doesn't yield false positives when the value is
        # 123.
        if value.is_a? Numeric
          arel_field.matches("%\"#{field}\":#{json_value},%").
            or(arel_field.matches("%\"#{field}\":#{json_value}}%"))
        else
          arel_field.matches("%\"#{field}\":#{json_value}%")
        end
      end

      # Returns a SQL LIKE condition to be used to match the given field and
      # value in the serialized `object_changes`.
      def where_object_changes_condition(arel_field, field, value)
        ::ActiveSupport::Deprecation.warn(E_WHERE_OBJ_CHANGES)

        # Convert to JSON to handle strings and nulls correctly.
        json_value = value.to_json

        # Need to check first (before) and secondary (after) fields
        arel_field.matches("%\"#{field}\":[#{json_value},%").
          or(arel_field.matches("%\"#{field}\":[%,#{json_value}]%"))
      end
    end
  end
end
