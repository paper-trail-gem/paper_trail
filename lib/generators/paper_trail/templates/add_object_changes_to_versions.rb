class AddObjectChangesToVersions < ActiveRecord::Migration

  # The largest text column available in all supported RDBMS.
  # See `create_versions.rb` for details.
  TEXT_BYTES = 1_073_741_823

  def change
    add_column :versions, :object_changes, :text, limit: TEXT_BYTES
  end
end
