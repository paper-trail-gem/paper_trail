class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions, force: true do |t|
      t.string   :item_type, null: false
      t.string   :item_id,   null: false  # might be a UID
      t.string   :event,     null: false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at
    end
    add_index :versions, [:item_type, :item_id]
  end
end
