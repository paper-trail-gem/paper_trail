# frozen_string_literal: true

module PaperTrail
  module Queries
    module Versions
      # For public API documentation, see `where_object_changes_from` in
      # `paper_trail/version_concern.rb`.
      # @api private
      class WhereObjectChangesFrom
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
          if PaperTrail.config.object_changes_adapter&.respond_to?(:where_object_changes_from)
            return PaperTrail.config.object_changes_adapter.where_object_changes_from(
              @version_model_class, @attributes
            )
          end

          case @version_model_class.columns_hash["object_changes"].type
          when :jsonb, :json
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
            predicates.push(
              "(object_changes->>? ILIKE ?)"
            )
            values.concat([field, "[#{value.to_json},%"])
          end
          sql = predicates.join(" and ")
          @version_model_class.where(sql, *values)
        end

        # @api private
        def text
          arel_field = @version_model_class.arel_table[:object_changes]

          where_conditions = @attributes.map do |field, value|
            ::PaperTrail.serializer.where_object_changes_from_condition(arel_field, field, value)
          end

          where_conditions = where_conditions.reduce { |a, e| a.and(e) }
          @version_model_class.where(where_conditions)
        end
      end
    end
  end
end
