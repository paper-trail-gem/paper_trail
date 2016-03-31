require "yaml"

module PaperTrail
  module Serializers
    module YAML
      def load(string)
        ::YAML.load string
      end
      module_function :load

      def dump(object)
        ::YAML.dump object
      end
      module_function :dump

      # Returns a SQL condition to be used to match the given field and value
      # in the serialized object
      def where_object_condition(arel_field, field, value)
        arel_field.matches("%\n#{field}: #{value}\n%")
      end
      module_function :where_object_condition

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
      module_function :where_object_changes_condition

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
      module_function :yaml_engine_id
    end
  end
end
