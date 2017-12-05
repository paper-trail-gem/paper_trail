require "paper_trail/type_serializers/postgres_array_serializer"

module PaperTrail
  module AttributeSerializers
    # Values returned by some Active Record serializers are
    # not suited for writing JSON to a text column. This factory
    # replaces certain default Active Record serializers
    # with custom PaperTrail ones.
    module AttributeSerializerFactory
      def self.for(klass, attr)
        active_record_serializer = klass.type_for_attribute(attr)
        case active_record_serializer
        when ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array then
          TypeSerializers::PostgresArraySerializer.new(
            active_record_serializer.subtype,
            active_record_serializer.delimiter
          )
        else
          active_record_serializer
        end
      end
    end
  end
end
