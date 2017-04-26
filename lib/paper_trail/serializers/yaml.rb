require "yaml"

module PaperTrail
  module Serializers
    # The default serializer for, e.g. `versions.object`.
    module YAML
      extend self # makes all instance methods become module methods as well

      def load(string)
        with_unformatted_dates_and_times { ::YAML.load string }
      end

      def dump(object)
        with_unformatted_dates_and_times { ::YAML.dump object }
      end
      
      def with_unformatted_dates_and_times
        date_format, time_format = Date::DATE_FORMATS[:default], Time::DATE_FORMATS[:default]
        Date::DATE_FORMATS[:default] = Time::DATE_FORMATS[:default] = nil
        yield.tap { Date::DATE_FORMATS[:default], Time::DATE_FORMATS[:default] = date_format, time_format }
      end

      # Returns a SQL LIKE condition to be used to match the given field and
      # value in the serialized object.
      def where_object_condition(arel_field, field, value)
        arel_field.matches("%\n#{field}: #{value}\n%")
      end

      # Returns a SQL LIKE condition to be used to match the given field and
      # value in the serialized `object_changes`.
      def where_object_changes_condition(arel_field, field, value)
        # Need to check first (before) and secondary (after) fields
        m1 = "%\n#{field}:\n- #{value}\n%"
        m2 = "%\n#{field}:\n-%\n- #{value}\n%"
        arel_field.matches(m1).or(arel_field.matches(m2))
      end
    end
  end
end
