# frozen_string_literal: true

require "paper_trail/attribute_serializers/attribute_serializer_factory"

module PaperTrail
  # :nodoc:
  module AttributeSerializers
    # The `CastAttributeSerializer` (de)serializes model attribute values. For
    # example, the string "1.99" serializes into the integer `1` when assigned
    # to an attribute of type `ActiveRecord::Type::Integer`.
    class CastAttributeSerializer
      def initialize(klass)
        @klass = klass
      end

      private

      # Returns a hash mapping attributes to hashes that map strings to
      # integers. Example:
      #
      # ```
      # { "status" => { "draft"=>0, "published"=>1, "archived"=>2 } }
      # ```
      #
      # ActiveRecord::Enum was added in AR 4.1
      # http://edgeguides.rubyonrails.org/4_1_release_notes.html#active-record-enums
      def defined_enums
        @defined_enums ||= (@klass.respond_to?(:defined_enums) ? @klass.defined_enums : {})
      end

      def deserialize(attr, val)
        if defined_enums[attr] && val.is_a?(::String)
          # Because PT 4 used to save the string version of enums to `object_changes`
          val
        elsif val.is_a?(ActiveRecord::Type::Time::Value) && val.instance_variable_defined?(:@time)
          # A Value that wrapped a UTC `TimeWithZone` loads from YAML with
          # `@utc`, `@zone` and `@time` but no delegate, so the factory would
          # throw a delegation error. See
          # https://github.com/rails/rails/issues/43966
          # Other Values (e.g. written when `Time.zone` is not UTC) wrap a plain
          # `Time`, so they load with a delegate and no `@time`, and go to the
          # factory.
          val.instance_variable_get(:@time)
        else
          AttributeSerializerFactory.for(@klass, attr).deserialize(val)
        end
      end

      def serialize(attr, val)
        AttributeSerializerFactory.for(@klass, attr).serialize(val)
      end
    end
  end
end
