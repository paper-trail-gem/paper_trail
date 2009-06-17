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
    #t.string    :type
  end

  create_table :versions, :force => true do |t|
    t.string   :item_type, :null => false
    t.integer  :item_id,   :null => false
    t.string   :event,     :null => false
    t.string   :whodunnit
    t.text     :object
    t.datetime :created_at
  end

end
