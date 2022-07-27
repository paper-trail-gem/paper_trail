# frozen_string_literal: true

require "yaml"

module PaperTrail
  module Serializers
    # The default serializer for, e.g. `versions.object`.
    module YAML
      extend self # makes all instance methods become module methods as well

      def load(string)
        if use_safe_load?
          ::YAML.safe_load(
            string,
            permitted_classes: ::ActiveRecord.yaml_column_permitted_classes,
            aliases: true
          )
        elsif ::YAML.respond_to?(:unsafe_load)
          ::YAML.unsafe_load(string)
        else
          ::YAML.load(string)
        end
      end

      # @param object (Hash | HashWithIndifferentAccess) - Coming from
      # `recordable_object` `object` will be a plain `Hash`. However, due to
      # recent [memory optimizations](https://github.com/paper-trail-gem/paper_trail/pull/1189),
      # when coming from `recordable_object_changes`, it will be a `HashWithIndifferentAccess`.
      def dump(object)
        object = object.to_hash if object.is_a?(HashWithIndifferentAccess)
        ::YAML.dump object
      end

      # Returns a SQL LIKE condition to be used to match the given field and
      # value in the serialized object.
      def where_object_condition(arel_field, field, value)
        arel_field.matches("%\n#{field}: #{value}\n%")
      end

      private

      # `use_yaml_unsafe_load` was added in 7.0.3.1, will be removed in 7.1.0?
      def use_safe_load?
        defined?(ActiveRecord.use_yaml_unsafe_load) &&
          !ActiveRecord.use_yaml_unsafe_load
      end
    end
  end
end
