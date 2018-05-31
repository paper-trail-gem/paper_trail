# frozen_string_literal: true

module PaperTrail
  module ObjectDiffAdapters
    # Allows storing only incremental changes in the object_changes column
    # Uses HashDiff (https://github.com/liufengyun/hashdiff)
    class HashDiff
      def diff(changes)
        diff_changes = {}
        changes.each do |field, value_changes|
          diff_changes[field] = HashDiff.diff(value_changes[0], value_changes[1], array_path: true)
        end
        diff_changes
      end
    end
  end
end
