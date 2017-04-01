# Use this template to report PaperTrail bugs.
# Please include only the minimum code necessary to reproduce your issue.
require "bundler/inline"

# STEP ONE: What versions are you using?
gemfile(true) do
  ruby "2.3.1"
  source "https://rubygems.org"
  gem "activerecord", "5.0.0"
  gem "minitest", "5.9.0"
  gem "paper_trail", "5.2.0", require: false
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = nil
ActiveRecord::Schema.define do
  # STEP TWO: Define your tables here.
  create_table :users, force: true do |t|
    t.text :first_name, null: false
    t.timestamps null: false
  end

  create_table :versions do |t|
    t.string :item_type, null: false
    t.integer :item_id, null: false
    t.string :event, null: false
    t.string :whodunnit
    t.text :object, limit: 1_073_741_823
    t.text :object_changes, limit: 1_073_741_823
    t.integer :transaction_id
    t.datetime :created_at
  end
  add_index :versions, %i(item_type item_id)
  add_index :versions, [:transaction_id]

  create_table :version_associations do |t|
    t.integer  :version_id
    t.string   :foreign_key_name, null: false
    t.integer  :foreign_key_id
  end
  add_index :version_associations, [:version_id]
  add_index :version_associations, %i(foreign_key_name foreign_key_id),
    name: "index_version_associations_on_foreign_key"
end
ActiveRecord::Base.logger = Logger.new(STDOUT)
require "paper_trail/config"

# STEP THREE: Configure PaperTrail as you would in your initializer
PaperTrail::Config.instance.track_associations = true

require "paper_trail"

# STEP FOUR: Define your AR models here.
class User < ActiveRecord::Base
  has_paper_trail
end

# STEP FIVE: Please write a test that demonstrates your issue.
class BugTest < ActiveSupport::TestCase
  def test_1
    assert_difference(-> { PaperTrail::Version.count }, +1) {
      User.create(first_name: "Jane")
    }
  end
end

# STEP SIX: Run this script using `ruby my_bug_report.rb`
