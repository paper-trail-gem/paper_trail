# frozen_string_literal: true

module PaperTrail
  module Queries
    module Versions
      # For public API documentation, see `where_attribute_changes` in
      # `paper_trail/version_concern.rb`.
      # @api private
      class WhereAttributeChanges
        # - version_model_class - The class that VersionConcern was mixed into.
        # - attribute - An attribute that changed. See the public API
        #   documentation for details.
        # @api private
        def initialize(version_model_class, attribute)
          @version_model_class = version_model_class
          @attribute = attribute
        end

        # @api private
        def execute
          if PaperTrail.config.object_changes_adapter.respond_to?(:where_attribute_changes)
            return PaperTrail.config.object_changes_adapter.where_attribute_changes(
              @version_model_class, @attribute
            )
          end
          column_type = @version_model_class.columns_hash["object_changes"].type
          case column_type
          when :jsonb, :json
            json
          else
            raise UnsupportedColumnType.new(
              method: "where_attribute_changes",
              expected: "json or jsonb",
              actual: column_type
            )
          end
        end

        private

        # @api private
        def json
          sql = "object_changes -> ? IS NOT NULL"

          @version_model_class.where(sql, @attribute)
        end
      end
    end
  end
end
