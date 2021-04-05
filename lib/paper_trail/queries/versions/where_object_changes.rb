# frozen_string_literal: true

module PaperTrail
  module Queries
    module Versions
      # For public API documentation, see `where_object_changes` in
      # `paper_trail/version_concern.rb`.
      # @api private
      class WhereObjectChanges
        # - version_model_class - The class that VersionConcern was mixed into.
        # - attributes - A `Hash` of attributes and values. See the public API
        #   documentation for details.
        # @api private
        def initialize(version_model_class, attributes)
          @version_model_class = version_model_class

          # Currently, this `deep_dup` is necessary because the `jsonb` branch
          # modifies `@attributes`, and that would be a nasty suprise for
          # consumers of this class.
          # TODO: Stop modifying `@attributes`, then remove `deep_dup`.
          @attributes = attributes.deep_dup
        end

        # @api private
        def execute
          if PaperTrail.config.object_changes_adapter.respond_to?(:where_object_changes)
            return PaperTrail.config.object_changes_adapter.where_object_changes(
              @version_model_class, @attributes
            )
          end
          column_type = @version_model_class.columns_hash["object_changes"].type
          case column_type
          when :jsonb
            jsonb
          when :json
            json
          else
            raise UnsupportedColumnType.new(
              method: "where_object_changes",
              expected: "json or jsonb",
              actual: column_type
            )
          end
        end

        private

        # @api private
        def json
          predicates = []
          values = []
          @attributes.each do |field, value|
            predicates.push(
              "((object_changes->>? ILIKE ?) OR (object_changes->>? ILIKE ?))"
            )
            values.concat([field, "[#{value.to_json},%", field, "[%,#{value.to_json}]%"])
          end
          sql = predicates.join(" and ")
          @version_model_class.where(sql, *values)
        end

        # @api private
        def jsonb
          @attributes.each { |field, value| @attributes[field] = [value] }
          @version_model_class.where("object_changes @> ?", @attributes.to_json)
        end
      end
    end
  end
end
