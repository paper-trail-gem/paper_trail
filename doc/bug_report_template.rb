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
  ruby '2.2.3'
  source 'https://rubygems.org'
  gem 'activerecord', '4.2.0'
  gem 'minitest', '5.8.3'
  gem 'paper_trail', '4.0.0', require: false
  gem 'sqlite3'
end

require 'active_record'
require 'minitest/autorun'
require 'logger'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)
require 'paper_trail'

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
    name: 'index_version_associations_on_foreign_key'
  # respect of #685 issue
  create_table :supply_chain_requirement_versions do |t|
    	t.string   :item_type,      null: false
	    t.integer  :item_id,        null: false
	    t.string   :event,          null: false
	    t.string   :whodunnit
	    t.json     :object
	    t.datetime :created_at
	    t.integer  :transaction_id
  end
  create_table :supply_chain_versions, force: true do |t|
	    t.string   :item_type,      null: false
	    t.integer  :item_id,        null: false
	    t.string   :event,          null: false
	    t.string   :whodunnit
	    t.json     :object
	    t.datetime :created_at
	    t.integer  :transaction_id
  end
  # end
end

class User < ActiveRecord::Base
  has_paper_trail
end
# respect of #685 issue
class SupplyChainVersion < PaperTrail::Version
  self.table_name = :supply_chain_versions
end

class SupplyChainRequirementVersion < PaperTrail::Version
  self.table_name = :supply_chain_requirement_versions
end

class SupplyChainRequirement < ActiveRecord::Base
  has_paper_trail :class_name => 'SupplyChainRequirementVersion'
end

class SupplyChain <  ActiveRecord::Base
  has_paper_trail :class_name => 'SupplyChainVersion', :only => [:compliant_status,:compliant_description]
  has_many :supply_chain_requirements, inverse_of: :supply_chain
end
# end

class BugTest < ActiveSupport::TestCase
  def test_1
    assert_difference(-> { PaperTrail::Version.count }, +1) {
      User.create(first_name: "Jane")
    }
  end
  
  # respect of #685 issue
  def test_2
    requirements = SupplyChain.find(4).versions.find(6).reify(has_many: true).supply_chain_requirements
    assert_equal(1, requirements.length) # but returning length 2 
  end
  # end
end
