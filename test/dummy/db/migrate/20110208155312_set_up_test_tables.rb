class SetUpTestTables < ActiveRecord::Migration
  def self.up
    create_table :widgets, :force => true do |t|
      t.string    :name
      t.text      :a_text
      t.integer   :an_integer
      t.float     :a_float
      t.decimal   :a_decimal
      t.datetime  :a_datetime
      t.time      :a_time
      t.date      :a_date
      t.boolean   :a_boolean
      t.datetime  :created_at, :updated_at
      t.string    :sacrificial_column
      t.string    :type
    end

    create_table :versions, :force => true do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.text     :object_changes
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

    create_table :wotsits, :force => true do |t|
      t.integer :widget_id
      t.string  :name
      t.datetime :created_at, :updated_at
    end

    create_table :fluxors, :force => true do |t|
      t.integer :widget_id
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

    create_table :songs, :force => true do |t|
      t.integer :length
    end

    create_table :posts, :force => true do |t|
      t.string :title
      t.string :content
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

    create_table :translations, :force => true do |t|
      t.string    :headline
      t.string    :content
      t.string    :language_code
      t.string    :type
    end
  end

  def self.down
    drop_table :animals
    drop_table :posts
    drop_table :songs
    drop_table :people
    drop_table :authorships
    drop_table :books
    drop_table :articles
    drop_table :fluxors
    drop_table :wotsits
    remove_index :post_versions, :column => [:item_type, :item_id]
    drop_table :post_versions
    remove_index :versions, :column => [:item_type, :item_id]
    drop_table :versions
    drop_table :widgets
    drop_table :documents
    drop_table :legacy_widgets
    drop_table :translations
  end
end
