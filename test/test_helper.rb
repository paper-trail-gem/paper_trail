# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

#ActionMailer::Base.delivery_method = :test
#ActionMailer::Base.perform_deliveries = true
#ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

require 'shoulda'
require 'ffaker'

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# global setup block resetting Thread.current
class ActiveSupport::TestCase
  teardown do
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
end
