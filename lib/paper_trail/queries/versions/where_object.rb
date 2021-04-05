# frozen_string_literal: true

module PaperTrail
  module Queries
    module Versions
      # For public API documentation, see `where_object` in
      # `paper_trail/version_concern.rb`.
      # @api private
      class WhereObject
        # - version_model_class - The class that VersionConcern was mixed into.
        # - attributes - A `Hash` of attributes and values. See the public API
        #   documentation for details.
        # @api private
        def initialize(version_model_class, attributes)
          @version_model_class = version_model_class
          @attributes = attributes
        end

        # @api private
        def execute
          column = @version_model_class.columns_hash["object"]
          raise Error, "where_object requires an object column" unless column

          case column.type
          when :jsonb
            jsonb
          when :json
            json
          else
            text
          end
        end

        private

        # @api private
        def json
          predicates = []
          values = []
          @attributes.each do |field, value|
            predicates.push "object->>? = ?"
            values.concat([field, value.to_s])
          end
          sql = predicates.join(" and ")
          @version_model_class.where(sql, *values)
        end

        # @api private
        def jsonb
          @version_model_class.where("object @> ?", @attributes.to_json)
        end

        # @api private
        def text
          arel_field = @version_model_class.arel_table[:object]
          where_conditions = @attributes.map { |field, value|
            ::PaperTrail.serializer.where_object_condition(arel_field, field, value)
          }
          where_conditions = where_conditions.reduce { |a, e| a.and(e) }
          @version_model_class.where(where_conditions)
        end
      end
    end
  end
end
