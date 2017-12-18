begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  ruby '2.4.1'
  source 'https://rubygems.org'
  gem 'activerecord', '5.0.6'
  gem 'paper_trail', '8.1.1', path: '.', require: false
  gem 'sqlite3'
end

require 'active_record'
require 'minitest/autorun'
require 'logger'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :documents, force: true do |t|
    t.timestamps null: false
  end
  create_table :assignments, force: true do |t|
    t.string :type, null: false
    t.integer :document_id, null: false
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
    name: 'index_version_associations_on_foreign_key'
end

require 'paper_trail/config'
PaperTrail::Config.instance.track_associations = true
require 'paper_trail'

class Document < ActiveRecord::Base
  has_paper_trail
  has_one :authorship
end

class Assignment < ActiveRecord::Base
  belongs_to :document
end

class Authorship < Assignment
  has_paper_trail
end

class BugTest < ActiveSupport::TestCase
  def test_authorship
    doc = Document.create!
    assert_equal 1, doc.versions.count
    Authorship.create! document: doc
    doc.paper_trail.touch_with_version
    assert_equal 2, doc.versions.count
    rfy_doc = doc.versions[1].reify(has_many: true, has_one: true)
    assert_equal "Authorship", rfy_doc.authorship.class.name
  end
end
