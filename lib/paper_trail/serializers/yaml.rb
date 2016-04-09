require "yaml"

module PaperTrail
  module Serializers
    # The default serializer for, e.g. `versions.object`.
    module YAML
      extend self # makes all instance methods become module methods as well

      def load(string)
        ::YAML.load string
      end

      def dump(object)
        ::YAML.dump object
      end

      # Returns a SQL condition to be used to match the given field and value
      # in the serialized object
      def where_object_condition(arel_field, field, value)
        arel_field.matches("%\n#{field}: #{value}\n%")
      end

      # Returns a SQL condition to be used to match the given field and value
      # in the serialized object_changes
      def where_object_changes_condition(arel_field, field, value)
        # Need to check first (before) and secondary (after) fields
        m1 = nil
        m2 = nil
        case yaml_engine_id
        when :psych
          m1 = "%\n#{field}:\n- #{value}\n%"
          m2 = "%\n#{field}:\n-%\n- #{value}\n%"
        when :syck
          # Syck adds extra spaces into array dumps
          m1 = "%\n#{field}: \n%- #{value}\n%"
          m2 = "%\n#{field}: \n-%\n- #{value}\n%"
        else
          raise "Unknown yaml engine"
        end
        arel_field.matches(m1).or(arel_field.matches(m2))
      end

      # Returns a symbol identifying the YAML engine. Syck was removed from
      # the ruby stdlib in ruby 2.0, but is still available as a gem.
      # @api private
      def yaml_engine_id
        if (defined?(::YAML::ENGINE) && ::YAML::ENGINE.yamler == "psych") ||
            (defined?(::Psych) && ::YAML == ::Psych)
          :psych
        else
          :syck
        end
      end
    end
  end
end
