require 'yaml'

module PaperTrail
  module Serializers
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
        if (defined?(::YAML::ENGINE) && ::YAML::ENGINE.yamler == 'psych') ||
          (defined?(::Psych) && ::YAML == ::Psych)
          arel_field.matches("%\n#{field}:\n- #{value}\n%").
            or(arel_field.matches("%\n#{field}:\n-%\n- #{value}\n%"))
        else # Syck adds extra spaces into array dumps
          arel_field.matches("%\n#{field}: \n%- #{value}\n%").
            or(arel_field.matches("%\n#{field}: \n-%\n- #{value}\n%"))
        end
      end
    end
  end
end
