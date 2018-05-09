# frozen_string_literal: true

module PaperTrail
  module Serializers
    # An alternate serializer for, e.g. `versions.object`.
    module JSON
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

      def where_object_changes_condition(*)
        raise <<-STR.squish.freeze
          where_object_changes no longer supports reading JSON from a text
          column. The old implementation was inaccurate, returning more records
          than you wanted. This feature was deprecated in 7.1.0 and removed in
          8.0.0. The json and jsonb datatypes are still supported. See the
          discussion at https://github.com/paper-trail-gem/paper_trail/issues/803
        STR
      end
    end
  end
end
