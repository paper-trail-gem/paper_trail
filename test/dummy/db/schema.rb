# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20110208155312) do

  create_table "animals", force: :cascade do |t|
    t.string "name"
    t.string "species"
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.string "content"
    t.string "abstract"
    t.string "file_upload"
  end

  create_table "authorships", force: :cascade do |t|
    t.integer "book_id"
    t.integer "author_id"
  end

  create_table "banana_versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_banana_versions_on_item_type_and_item_id"
  end

  create_table "bananas", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bar_habtms", force: :cascade do |t|
    t.string "name"
  end

  create_table "bar_habtms_foo_habtms", id: false, force: :cascade do |t|
    t.integer "foo_habtm_id"
    t.integer "bar_habtm_id"
    t.index ["bar_habtm_id"], name: "index_bar_habtms_foo_habtms_on_bar_habtm_id"
    t.index ["foo_habtm_id"], name: "index_bar_habtms_foo_habtms_on_foo_habtm_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "title"
  end

  create_table "boolits", force: :cascade do |t|
    t.string  "name"
    t.boolean "scoped", default: true
  end

  create_table "callback_modifiers", force: :cascade do |t|
    t.string  "some_content"
    t.boolean "deleted",      default: false
  end

  create_table "chapters", force: :cascade do |t|
    t.string "name"
  end

  create_table "citations", force: :cascade do |t|
    t.integer "quotation_id"
  end

  create_table "custom_primary_key_record_versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.string   "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "idx_cust_pk_item"
  end

  create_table "custom_primary_key_records", primary_key: "uuid", id: :string, force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["uuid"], unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
  end

  create_table "documents", force: :cascade do |t|
    t.string "name"
  end

  create_table "editors", force: :cascade do |t|
    t.string "name"
  end

  create_table "editorships", force: :cascade do |t|
    t.integer "book_id"
    t.integer "editor_id"
  end

  create_table "fluxors", force: :cascade do |t|
    t.integer "widget_id"
    t.string  "name"
  end

  create_table "foo_habtms", force: :cascade do |t|
    t.string "name"
  end

  create_table "fruits", force: :cascade do |t|
    t.string "name"
    t.string "color"
  end

  create_table "gadgets", force: :cascade do |t|
    t.string   "name"
    t.string   "brand"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "legacy_widgets", force: :cascade do |t|
    t.string  "name"
    t.integer "version"
  end

  create_table "line_items", force: :cascade do |t|
    t.integer "order_id"
    t.string  "product"
  end

  create_table "not_on_updates", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "on_create", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "on_destroy", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "on_empty_array", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "on_update", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.integer "customer_id"
    t.string  "order_date"
  end

  create_table "paragraphs", force: :cascade do |t|
    t.integer "section_id"
    t.string  "name"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.string "time_zone"
  end

  create_table "post_versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.string   "ip"
    t.string   "user_agent"
    t.index ["item_type", "item_id"], name: "index_post_versions_on_item_type_and_item_id"
  end

  create_table "post_with_statuses", force: :cascade do |t|
    t.integer  "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.string "content"
  end

  create_table "quotations", force: :cascade do |t|
    t.integer "chapter_id"
  end

  create_table "sections", force: :cascade do |t|
    t.integer "chapter_id"
    t.string  "name"
  end

  create_table "skippers", force: :cascade do |t|
    t.string   "name"
    t.datetime "another_timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "songs", force: :cascade do |t|
    t.integer "length"
  end

  create_table "things", force: :cascade do |t|
    t.string "name"
  end

  create_table "translations", force: :cascade do |t|
    t.string "headline"
    t.string "content"
    t.string "language_code"
    t.string "type"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "type",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",                         null: false
    t.integer  "item_id",                           null: false
    t.string   "event",                             null: false
    t.string   "whodunnit"
    t.text     "object",         limit: 1073741823
    t.text     "object_changes", limit: 1073741823
    t.integer  "transaction_id"
    t.datetime "created_at"
    t.integer  "answer"
    t.string   "action"
    t.string   "question"
    t.integer  "article_id"
    t.string   "title"
    t.string   "ip"
    t.string   "user_agent"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "whatchamajiggers", force: :cascade do |t|
    t.string  "owner_type"
    t.integer "owner_id"
    t.string  "name"
  end

  create_table "widgets", force: :cascade do |t|
    t.string   "name"
    t.text     "a_text"
    t.integer  "an_integer"
    t.float    "a_float"
    t.decimal  "a_decimal",  precision: 6, scale: 4
    t.datetime "a_datetime"
    t.time     "a_time"
    t.date     "a_date"
    t.boolean  "a_boolean"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wotsits", force: :cascade do |t|
    t.integer  "widget_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
