require "paper_trail/attribute_serializers/array_serializer"

module PaperTrail
  module AttributeSerializers
    # Values returned by some Active Record serializers are
    # not suited for JSON encoding. This factory
    # replaces certain default Active Record serializers
    # with custom PaperTrail ones.
    module AttributeSerializer
      def self.for(klass, attr)
        case active_record_serializer = klass.type_for_attribute(attr)
        when ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array then ArraySerializer
        else active_record_serializer
        end
      end
    end
  end
end
