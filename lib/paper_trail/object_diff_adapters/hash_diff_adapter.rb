# frozen_string_literal: true

module PaperTrail
  module ObjectDiffAdapters
    # Allows storing only incremental changes in the object_changes column
    # Uses HashDiff (https://github.com/liufengyun/hashdiff)
    class HashDiffAdapter
      def diff(changes)
        diff_changes = {}
        changes.each do |field, value_changes|
          diff_changes[field] = HashDiff.diff(value_changes[0], value_changes[1], array_path: true)
        end
        diff_changes
      end

      def where_object_changes(version_model_class, attributes)
        scope = version_model_class
        attributes.each do |k, v|
          scope = scope.where("(((object_changes -> ?)::jsonb ->> 0)::jsonb @> ?)", k.to_s, v.to_s)
        end
        scope
      end
    end
  end
end
