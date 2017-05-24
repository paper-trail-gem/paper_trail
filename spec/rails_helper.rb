# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
ENV["DB"] ||= "sqlite"

unless File.exist?(File.expand_path("../../test/dummy/config/database.yml", __FILE__))
  warn "WARNING: No database.yml detected for the dummy app, please run `rake prepare` first"
end

require "spec_helper"
require File.expand_path("../../test/dummy/config/environment", __FILE__)
require "rspec/rails"
require "paper_trail/frameworks/rspec"
require "ffaker"
require "timecop"

# prevent Test::Unit's AutoRunner from executing during RSpec's rake task
Test::Unit.run = true if defined?(Test::Unit) && Test::Unit.respond_to?(:run=)

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if ActiveRecord::Migration.respond_to?(:check_pending!)

require "database_cleaner"
DatabaseCleaner.strategy = :truncation

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = active_record_gem_version >= ::Gem::Version.new("5")

  # In rails < 5, some tests seem to require DatabaseCleaner-truncation.
  # Truncation is about three times slower than transaction rollback, so it'll
  # be nice when we can drop support for rails < 5.
  if active_record_gem_version < ::Gem::Version.new("5")
    config.before(:each) { DatabaseCleaner.start }
    config.after(:each) { DatabaseCleaner.clean }
  end
end
