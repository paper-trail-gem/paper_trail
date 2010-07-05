ActiveRecord::Schema.define(:version => 0) do

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
    t.datetime :created_at

    # Metadata columns.
    t.integer :answer
    t.string  :question
    t.integer :article_id

    # Controller info columns.
    t.string :ip
    t.string :user_agent
  end
  add_index :versions, [:item_type, :item_id]

  create_table :wotsits, :force => true do |t|
    t.integer :widget_id
    t.string  :name
  end

  create_table :fluxors, :force => true do |t|
    t.integer :widget_id
    t.string  :name
  end

  create_table :articles, :force => true do |t|
    t.string :title
    t.string :content
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
  end

end
