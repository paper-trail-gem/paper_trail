# frozen_string_literal: true

# Parts of this migration must be kept in sync with
# `lib/generators/paper_trail/templates/create_versions.rb`
#
# Starting with AR 5.1, we must specify which version of AR we are using.
# I tried using `const_get` but I got a `NameError`, then I learned about
# `::ActiveRecord::Migration::Current`.
class SetUpTestTables < (
  if ::ActiveRecord::VERSION::MAJOR >= 5
    ::ActiveRecord::Migration::Current
  else
    ::ActiveRecord::Migration
  end
)
  MYSQL_ADAPTERS = [
    "ActiveRecord::ConnectionAdapters::MysqlAdapter",
    "ActiveRecord::ConnectionAdapters::Mysql2Adapter"
  ].freeze
  TEXT_BYTES = 1_073_741_823

  def up
    create_table :on_create, force: true do |t|
      t.string :name, null: false
    end

    create_table :on_destroy, force: true do |t|
      t.string :name, null: false
    end

    create_table :on_empty_array, force: true do |t|
      t.string :name, null: false
    end

    create_table :on_touch, force: true do |t|
      t.string :name, null: false
    end

    create_table :on_update, force: true do |t|
      t.string :name, null: false
    end

    # Classes: Vehicle, Car, Truck
    create_table :vehicles, force: true do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.integer :owner_id
      t.timestamps null: false, limit: 6
    end

    create_table :skippers, force: true do |t|
      t.string     :name
      t.datetime   :another_timestamp, limit: 6
      t.timestamps null: true, limit: 6
    end

    create_table :widgets, force: true do |t|
      t.string    :name
      t.text      :a_text
      t.integer   :an_integer
      t.float     :a_float
      t.decimal   :a_decimal, precision: 6, scale: 4
      t.datetime  :a_datetime, limit: 6
      t.time      :a_time
      t.date      :a_date
      t.boolean   :a_boolean
      t.string    :type
      t.timestamps null: true, limit: 6
    end

    if ENV["DB"] == "postgres"
      create_table :postgres_users, force: true do |t|
        t.string     :name
        t.integer    :post_ids,    array: true
        t.datetime   :login_times, array: true, limit: 6
        t.timestamps null: true, limit: 6
      end
    end

    create_table :versions, versions_table_options do |t|
      t.string   :item_type, item_type_options(null: false)
      t.integer  :item_id, null: false
      t.string   :item_subtype, item_type_options(null: true)
      t.string   :event, null: false
      t.string   :whodunnit
      t.text     :object, limit: TEXT_BYTES
      t.text     :object_changes, limit: TEXT_BYTES
      t.integer  :transaction_id
      t.datetime :created_at, limit: 6

      # Metadata columns.
      t.integer :answer
      t.string :action
      t.string  :question
      t.integer :article_id
      t.string :title

      # Controller info columns.
      t.string :ip
      t.string :user_agent
    end
    add_index :versions, %i[item_type item_id]

    create_table :version_associations do |t|
      t.integer  :version_id
      t.string   :foreign_key_name, null: false
      t.integer  :foreign_key_id
      t.string   :foreign_type, null: false
    end
    add_index :version_associations, [:version_id]
    add_index :version_associations,
      %i[foreign_key_name foreign_key_id foreign_type],
      name: "index_version_associations_on_foreign_key"

    create_table :post_versions, force: true do |t|
      t.string   :item_type, null: false
      t.integer  :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at, limit: 6

      # Controller info columns.
      t.string :ip
      t.string :user_agent
    end
    add_index :post_versions, %i[item_type item_id]

    # Uses custom versions table `no_object_versions`.
    create_table :no_objects, force: true do |t|
      t.string :letter, null: false, limit: 1
      t.timestamps null: false, limit: 6
    end

    # This table omits the `object` column.
    create_table :no_object_versions, force: true do |t|
      t.string   :item_type, null: false
      t.integer  :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.datetime :created_at, limit: 6
      t.text     :object_changes, limit: TEXT_BYTES
      t.integer  :metadatum
    end
    add_index :no_object_versions, %i[item_type item_id]

    if ENV["DB"] == "postgres"
      create_table :json_versions, force: true do |t|
        t.string   :item_type, null: false
        t.integer  :item_id,   null: false
        t.string   :event,     null: false
        t.string   :whodunnit
        t.json     :object
        t.json     :object_changes
        t.datetime :created_at, limit: 6
      end
      add_index :json_versions, %i[item_type item_id]
    end

    create_table :not_on_updates, force: true do |t|
      t.timestamps null: true, limit: 6
    end

    create_table :bananas, force: true do |t|
      t.timestamps null: true, limit: 6
    end

    create_table :banana_versions, force: true do |t|
      t.string   :item_type, null: false
      t.integer  :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at, limit: 6
    end
    add_index :banana_versions, %i[item_type item_id]

    create_table :wotsits, force: true do |t|
      t.integer :widget_id
      t.string  :name
      t.timestamps null: true, limit: 6
    end

    create_table :fluxors, force: true do |t|
      t.integer :widget_id
      t.string  :name
    end

    create_table :whatchamajiggers, force: true do |t|
      t.string  :owner_type
      t.integer :owner_id
      t.string  :name
    end

    create_table :articles, force: true do |t|
      t.string :title
      t.string :content
      t.string :abstract
      t.string :file_upload
    end

    create_table :books, force: true do |t|
      t.string :title
    end

    create_table :authorships, force: true do |t|
      t.integer :book_id
      t.integer :author_id
    end

    create_table :people, force: true do |t|
      t.string :name
      t.string :time_zone
      t.integer :mentor_id
    end

    create_table :editorships, force: true do |t|
      t.integer :book_id
      t.integer :editor_id
    end

    create_table :editors, force: true do |t|
      t.string :name
    end

    create_table :songs, force: true do |t|
      t.integer :length
    end

    create_table :posts, force: true do |t|
      t.string :title
      t.string :content
    end

    create_table :post_with_statuses, force: true do |t|
      t.integer :status
      t.timestamps null: false, limit: 6
    end

    create_table :animals, force: true do |t|
      t.string :name
      t.string :species # single table inheritance column
    end

    create_table :pets, force: true do |t|
      t.integer :owner_id
      t.integer :animal_id
    end

    create_table :documents, force: true do |t|
      t.string :name
    end

    create_table :legacy_widgets, force: true do |t|
      t.string    :name
      t.integer   :version
    end

    create_table :things, force: true do |t|
      t.string    :name
      t.references :person
    end

    create_table :translations, force: true do |t|
      t.string    :headline
      t.string    :content
      t.string    :language_code
      t.string    :type
    end

    create_table :gadgets, force: true do |t|
      t.string    :name
      t.string    :brand
      t.timestamps null: true, limit: 6
    end

    create_table :customers, force: true do |t|
      t.string :name
    end

    create_table :orders, force: true do |t|
      t.integer :customer_id
      t.string  :order_date
    end

    create_table :line_items, force: true do |t|
      t.integer :order_id
      t.string  :product
    end

    create_table :fruits, force: true do |t|
      t.string :name
      t.string :color
    end

    create_table :boolits, force: true do |t|
      t.string :name
      t.boolean :scoped, default: true
    end

    create_table :callback_modifiers, force: true do |t|
      t.string  :some_content
      t.boolean :deleted, default: false
    end

    create_table :chapters, force: true do |t|
      t.string :name
    end

    create_table :sections, force: true do |t|
      t.integer :chapter_id
      t.string :name
    end

    create_table :paragraphs, force: true do |t|
      t.integer :section_id
      t.string :name
    end

    create_table :quotations, force: true do |t|
      t.integer :chapter_id
    end

    create_table :citations, force: true do |t|
      t.integer :quotation_id
    end

    create_table :foo_habtms, force: true do |t|
      t.string :name
    end

    create_table :bar_habtms, force: true do |t|
      t.string :name
    end

    create_table :bar_habtms_foo_habtms, force: true, id: false do |t|
      t.integer :foo_habtm_id
      t.integer :bar_habtm_id
    end
    add_index :bar_habtms_foo_habtms, [:foo_habtm_id]
    add_index :bar_habtms_foo_habtms, [:bar_habtm_id]

    # custom_primary_key_records use a uuid column (string)
    create_table :custom_primary_key_records, id: false, force: true do |t|
      t.column :uuid, :string, primary_key: true
      t.string :name
      t.timestamps null: true, limit: 6
    end

    # and custom_primary_key_record_versions stores the uuid in item_id, a string
    create_table :custom_primary_key_record_versions, force: true do |t|
      t.string   :item_type, null: false
      t.string   :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at, limit: 6
    end
    add_index :custom_primary_key_record_versions, %i[item_type item_id], name: "idx_cust_pk_item"

    create_table :family_lines do |t|
      t.integer :parent_id
      t.integer :grandson_id
    end

    create_table :families do |t|
      t.string :name
      t.string :type            # For STI support
      t.string :path_to_stardom # Only used for celebrity families
      t.integer :parent_id
      t.integer :partner_id
    end
  end

  def down
    # Not actually irreversible, but there is no need to maintain this method.
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def item_type_options(null:)
    opt = { null: null }
    opt[:limit] = 191 if mysql?
    opt
  end

  def mysql?
    MYSQL_ADAPTERS.include?(connection.class.name)
  end

  def versions_table_options
    if mysql?
      { options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" }
    else
      {}
    end
  end
end
