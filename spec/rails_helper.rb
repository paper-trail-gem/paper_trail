# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
ENV["DB"] ||= 'sqlite'

unless File.exists?(File.expand_path('../../test/dummy/config/database.yml', __FILE__))
  warn "WARNING: No database.yml detected for the dummy app, please run `rake prepare` first"
end

require 'spec_helper'
require File.expand_path('../../test/dummy/config/environment', __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'ffaker'

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  # config.infer_spec_type_from_file_location!
end
