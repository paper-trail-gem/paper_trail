require 'paper_trail/attribute_serializers/array_serializer'

module PaperTrail
  module AttributeSerializers
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
