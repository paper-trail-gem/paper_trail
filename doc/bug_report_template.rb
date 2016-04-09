# Use this template to report PaperTrail bugs.
# It is based on the ActiveRecord template.
# https://github.com/rails/rails/blob/master/guides/bug_report_templates/active_record_gem.rb
begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  ruby "2.2.3"
  source "https://rubygems.org"
  gem "activerecord", "4.2.0"
  gem "minitest", "5.8.3"
  gem "paper_trail", "4.0.0", require: false
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
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
  add_index :versions, [:item_type, :item_id]
  add_index :versions, [:transaction_id]

  create_table :version_associations do |t|
    t.integer  :version_id
    t.string   :foreign_key_name, null: false
    t.integer  :foreign_key_id
  end
  add_index :version_associations, [:version_id]
  add_index :version_associations, [:foreign_key_name, :foreign_key_id],
    name: "index_version_associations_on_foreign_key"
end

# Require `paper_trail.rb` after the `version_associations` table
# exists so that PT will track associations.
require "paper_trail"

# Include your models here. Please only include the minimum code necessary to
# reproduce your issue.
class User < ActiveRecord::Base
  has_paper_trail
end

# Please write a test that demonstrates your issue by failing.
class BugTest < ActiveSupport::TestCase
  def test_1
    assert_difference(-> { PaperTrail::Version.count }, +1) {
      User.create(first_name: "Jane")
    }
  end
end
