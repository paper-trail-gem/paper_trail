ENV["RAILS_ENV"] = "test"
ENV["DB"] ||= "sqlite"

unless File.exists?(File.expand_path('../../test/dummy/config/database.yml', __FILE__))
  warn "WARNING: No database.yml detected for the dummy app, please run `rake prepare` first"
end

def using_mysql?
  @using_mysql ||= ActiveRecord::Base.connection_config[:adapter].to_sym == :mysql2
end

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'shoulda'
require 'ffaker'
require 'database_cleaner'

Rails.backtrace_cleaner.remove_silencers!

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# DatabaseCleaner is apparently necessary for doing proper transactions within MySQL (ugh)
DatabaseCleaner.strategy = :truncation

# global setup block resetting Thread.current
class ActiveSupport::TestCase
  if using_mysql?
    self.use_transactional_fixtures = false
    setup { DatabaseCleaner.start }
  end

  teardown do
    DatabaseCleaner.clean if using_mysql?
    Thread.current[:paper_trail] = nil
  end
end

#
# Helpers
#

def change_schema
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define do
    remove_column :widgets, :sacrificial_column
    add_column :versions, :custom_created_at, :datetime
  end
  ActiveRecord::Migration.verbose = true
  reset_version_class_column_info!
end

def restore_schema
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define do
    add_column :widgets, :sacrificial_column, :string
    remove_column :versions, :custom_created_at
  end
  ActiveRecord::Migration.verbose = true
  reset_version_class_column_info!
end

def reset_version_class_column_info!
  PaperTrail::Version.connection.schema_cache.clear!
  PaperTrail::Version.reset_column_information
end
