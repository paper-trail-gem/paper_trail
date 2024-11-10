# frozen_string_literal: true

require "paper_trail/type_serializers/postgres_array_serializer"
require "paper_trail/type_serializers/postgres_range_serializer"

module PaperTrail
  module AttributeSerializers
    # Values returned by some Active Record serializers are
    # not suited for writing JSON to a text column. This factory
    # replaces certain default Active Record serializers
    # with custom PaperTrail ones.
    #
    # @api private
    module AttributeSerializerFactory
      class << self
        # @api private
        def for(model_class, attr)
          active_record_serializer = model_class.type_for_attribute(attr)

          if ar_pg_array?(active_record_serializer)
            TypeSerializers::PostgresArraySerializer.new(
              active_record_serializer.subtype,
              active_record_serializer.delimiter
            )
          elsif ar_pg_range?(active_record_serializer)
            TypeSerializers::PostgresRangeSerializer.new(
              active_record_serializer
            )
          else
            active_record_serializer
          end
        end

        private

        # @api private
        def ar_pg_array?(obj)
          if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
            obj.instance_of?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
          else
            false
          end
        end

        # @api private
        def ar_pg_range?(obj)
          if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Range)
            obj.instance_of?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Range)
          else
            false
          end
        end
      end
    end
  end
end
