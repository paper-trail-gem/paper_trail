# https://github.com/airblade/paper_trail/issues/594

# Use this template to report PaperTrail bugs.
# It is based on the ActiveRecord template.
# https://github.com/rails/rails/blob/master/guides/bug_report_templates/active_record_gem.rb
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
  create_table :users, force: true do |t|
    t.text :first_name, null: false
    t.timestamps null: false
  end
  create_table :assignments, force: :cascade do |t|
    t.integer  :user_id, limit: 4,     null: false
    t.text     :name,                  null: false
    t.string   :type,    limit: 255,   null: false
    t.timestamps null: false
  end
  create_table :versions do |t|
    t.string :item_type, null: false
    t.string :item_sub_type
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

# STEP THREE: Configure PaperTrail as you would in your initializer
PaperTrail::Config.instance.track_associations = true

require 'paper_trail'

class User < ActiveRecord::Base
  has_many :authorship
  accepts_nested_attributes_for :authorship
  has_many :sponsorship
  accepts_nested_attributes_for :sponsorship
  has_paper_trail
end

class Assignment < ActiveRecord::Base
  belongs_to :user
  has_paper_trail
end

class Authorship < Assignment
end

class Sponsorship < Assignment
end

class BugTest < ActiveSupport::TestCase
  def test_authorship
    user = User.create!({first_name: "Jane", authorship_attributes: [{name: "Bob"}]})
    assert_equal 1, user.versions.count
    user.update!({first_name: "Denise", authorship_attributes: [{id: user.authorship.first.id, name: "Steve"}]})
    assert_equal 2, user.versions.count

    versioned_user = user.reload.versions.last.reify(has_many: true)
    assert_equal "Jane", versioned_user.first_name
    # Fails: Expected authorship name to be "Bob", the old authorship but it is actually "Steve", the current author.
    assert_equal "Bob", versioned_user.authorship.first.name

    user.update!({first_name: "Jessica", authorship_attributes: [{id: user.authorship.first.id, name: "Blake"}]})
    versioned_user = user.reload.versions.last.reify(has_many: true)
    assert_equal "Denise", versioned_user.first_name
    # Fails: Expected authorship name to be "Steve", the second authorship but it is "Blake", the current author.
    assert_equal "Steve", versioned_user.authorship.first.name

    # Polymorphic associations that point to STI models require you store the base model to function properly
    # http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#module-ActiveRecord::Associations::ClassMethods-label-Polymorphic+Associations
    assert_includes PaperTrail::Version.pluck(:item_type), "Assignment"
    assert_not_includes PaperTrail::Version.pluck(:item_type), "Authorship"
  end
end
