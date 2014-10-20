class CreateVersionAssociations < ActiveRecord::Migration
  def self.up
    create_table :version_associations do |t|
      t.integer  :version_id
      t.string   :foreign_key_name, :null => false
      t.integer  :foreign_key_id
    end
    add_index :version_associations, [:version_id]
    add_index :version_associations, [:foreign_key_name, :foreign_key_id], :name => 'index_on_foreign_key_name_and foreign_key_id'
  end

  def self.down
    remove_index :version_associations, [:version_id]
    remove_index :version_associations, [:foreign_key_name, :foreign_key_id], :name => 'index_on_foreign_key_name_and foreign_key_id'
    drop_table :version_associations
  end
end