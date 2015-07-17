class SetUpTestTables < ActiveRecord::Migration
  def self.up
    create_table :skippers, :force => true do |t|
      t.datetime :another_timestamp
      t.timestamps :null => true
    end

    create_table :widgets, :force => true do |t|
      t.string    :name
      t.text      :a_text
      t.integer   :an_integer
      t.float     :a_float
      t.decimal   :a_decimal, :precision => 6, :scale => 4
      t.datetime  :a_datetime
      t.time      :a_time
      t.date      :a_date
      t.boolean   :a_boolean
      t.string    :sacrificial_column
      t.string    :type
      t.timestamps :null => true
    end

    create_table :versions, :force => true do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.text     :object_changes
      t.integer  :transaction_id
      t.datetime :created_at

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
    add_index :versions, [:item_type, :item_id]

    create_table :version_associations do |t|
      t.integer  :version_id
      t.string   :foreign_key_name, :null => false
      t.integer  :foreign_key_id
    end
    add_index :version_associations, [:version_id]
    add_index :version_associations, [:foreign_key_name, :foreign_key_id], :name => 'index_version_associations_on_foreign_key'

    create_table :post_versions, :force => true do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at

      # Controller info columns.
      t.string :ip
      t.string :user_agent
    end
    add_index :post_versions, [:item_type, :item_id]

    if ENV['DB'] == 'postgres' && ::ActiveRecord::VERSION::MAJOR >= 4
      create_table :json_versions, :force => true do |t|
        t.string   :item_type, :null => false
        t.integer  :item_id,   :null => false
        t.string   :event,     :null => false
        t.string   :whodunnit
        t.json     :object
        t.json     :object_changes
        t.datetime :created_at
      end
      add_index :json_versions, [:item_type, :item_id]
    end

    create_table :not_on_updates, :force => true do |t|
      t.timestamps :null => true
    end

    create_table :bananas, :force => true do |t|
      t.timestamps :null => true
    end

    create_table :banana_versions, :force => true do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at
    end
    add_index :banana_versions, [:item_type, :item_id]

    create_table :wotsits, :force => true do |t|
      t.integer :widget_id
      t.string  :name
      t.timestamps :null => true
    end

    create_table :fluxors, :force => true do |t|
      t.integer :widget_id
      t.string  :name
    end

    create_table :whatchamajiggers, :force => true do |t|
      t.string  :owner_type
      t.integer :owner_id
      t.string  :name
    end

    create_table :articles, :force => true do |t|
      t.string :title
      t.string :content
      t.string :abstract
      t.string :file_upload
    end

    create_table :books, :force => true do |t|
      t.string :title
    end

    create_table :authorships, :force => true do |t|
      t.integer :book_id
      t.integer :person_id
    end

    create_table :people, :force => true do |t|
      t.string :name
      t.string :time_zone
    end

    create_table :editorships, :force => true do |t|
      t.integer :book_id
      t.integer :editor_id
    end

    create_table :editors, :force => true do |t|
      t.string :name
    end

    create_table :songs, :force => true do |t|
      t.integer :length
    end

    create_table :posts, :force => true do |t|
      t.string :title
      t.string :content
    end

    create_table :post_with_statuses, :force => true do |t|
      t.integer :status
    end

    create_table :animals, :force => true do |t|
      t.string :name
      t.string :species   # single table inheritance column
    end

    create_table :documents, :force => true do |t|
      t.string :name
    end

    create_table :legacy_widgets, :force => true do |t|
      t.string    :name
      t.integer   :version
    end

    create_table :things, :force => true do |t|
      t.string    :name
    end

    create_table :translations, :force => true do |t|
      t.string    :headline
      t.string    :content
      t.string    :language_code
      t.string    :type
    end

    create_table :gadgets, :force => true do |t|
      t.string    :name
      t.string    :brand
      t.timestamps :null => true
    end

    create_table :customers, :force => true do |t|
      t.string    :name
    end

    create_table :orders, :force => true do |t|
      t.integer :customer_id
      t.string  :order_date
    end

    create_table :line_items, :force => true do |t|
      t.integer :order_id
      t.string  :product
    end

    create_table :fruits, :force => true do |t|
      t.string :name
      t.string :color
    end

    create_table :boolits, :force => true do |t|
      t.string :name
      t.boolean :scoped, :default => true
    end
  end

  def self.down
    drop_table :animals
    drop_table :skippers
    drop_table :not_on_updates
    drop_table :posts
    drop_table :songs
    drop_table :editors
    drop_table :editorships
    drop_table :people
    drop_table :authorships
    drop_table :books
    drop_table :articles
    drop_table :whatchamajiggers
    drop_table :fluxors
    drop_table :wotsits
    remove_index :post_versions, :column => [:item_type, :item_id]
    drop_table :post_versions
    remove_index :versions, :column => [:item_type, :item_id]
    drop_table :versions
    if JsonVersion.table_exists?
      remove_index :json_versions, :column => [:item_type, :item_id]
      drop_table :json_versions
    end
    drop_table :widgets
    drop_table :documents
    drop_table :legacy_widgets
    drop_table :things
    drop_table :translations
    drop_table :gadgets
    drop_table :customers
    drop_table :orders
    drop_table :line_items
    drop_table :fruits
    drop_table :boolits
    remove_index :version_associations, :column => [:version_id]
    remove_index :version_associations, :name => 'index_version_associations_on_foreign_key'
    drop_table :version_associations
  end
end
