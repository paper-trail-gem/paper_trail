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
        elsif PaperTrail.active_record_gte_7_0? && val.is_a?(ActiveRecord::Type::Time::Value)
          # Because Rails 7 time attribute throws a delegation error when you deserialize
          # it with the factory.
          # See ActiveRecord::Type::Time::Value crashes when loaded from YAML on rails 7.0
          # https://github.com/rails/rails/issues/43966
          val.instance_variable_get(:@time)
        else
          AttributeSerializerFactory.for(@klass, attr).deserialize(val)
        end
      end

      def serialize(attr, val)
        serialized = AttributeSerializerFactory.for(@klass, attr).serialize(val)
        case serialized
        when Date, Time
          @klass.connection.type_cast(serialized)
        else
          serialized
        end
      end
    end
  end
end
