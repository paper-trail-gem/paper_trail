# encoding: UTF-8
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

  create_table "animals", force: true do |t|
    t.string "name"
    t.string "species"
  end

  create_table "articles", force: true do |t|
    t.string "title"
    t.string "content"
    t.string "abstract"
    t.string "file_upload"
  end

  create_table "authorships", force: true do |t|
    t.integer "book_id"
    t.integer "person_id"
  end

  create_table "books", force: true do |t|
    t.string "title"
  end

  create_table "customers", force: true do |t|
    t.string "name"
  end

  create_table "documents", force: true do |t|
    t.string "name"
  end

  create_table "editors", force: true do |t|
    t.string "name"
  end

  create_table "editorships", force: true do |t|
    t.integer "book_id"
    t.integer "editor_id"
  end

  create_table "fluxors", force: true do |t|
    t.integer "widget_id"
    t.string  "name"
  end

  create_table "gadgets", force: true do |t|
    t.string   "name"
    t.string   "brand"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "legacy_widgets", force: true do |t|
    t.string  "name"
    t.integer "version"
  end

  create_table "line_items", force: true do |t|
    t.integer "order_id"
    t.string  "product"
  end

  create_table "orders", force: true do |t|
    t.integer "customer_id"
    t.string  "order_date"
  end

  create_table "people", force: true do |t|
    t.string "name"
    t.string "time_zone"
  end

  create_table "post_versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.string   "ip"
    t.string   "user_agent"
  end

  add_index "post_versions", ["item_type", "item_id"], name: "index_post_versions_on_item_type_and_item_id"

  create_table "post_with_statuses", force: true do |t|
    t.integer "status"
  end

  create_table "posts", force: true do |t|
    t.string "title"
    t.string "content"
  end

  create_table "songs", force: true do |t|
    t.integer "length"
  end

  create_table "things", force: true do |t|
    t.string "name"
  end

  create_table "translations", force: true do |t|
    t.string "headline"
    t.string "content"
    t.string "language_code"
    t.string "type"
  end

  create_table "version_associations", force: true do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id"

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.text     "object_changes"
    t.integer  "transaction_id"
    t.datetime "created_at"
    t.integer  "answer"
    t.string   "action"
    t.string   "question"
    t.integer  "article_id"
    t.string   "title"
    t.string   "ip"
    t.string   "user_agent"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"

  create_table "whatchamajiggers", force: true do |t|
    t.string  "owner_type"
    t.integer "owner_id"
    t.string  "name"
  end

  create_table "widgets", force: true do |t|
    t.string   "name"
    t.text     "a_text"
    t.integer  "an_integer"
    t.float    "a_float"
    t.decimal  "a_decimal",          precision: 6, scale: 4
    t.datetime "a_datetime"
    t.time     "a_time"
    t.date     "a_date"
    t.boolean  "a_boolean"
    t.string   "sacrificial_column"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wotsits", force: true do |t|
    t.integer  "widget_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
