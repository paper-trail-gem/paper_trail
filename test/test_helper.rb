begin
  require 'pry-nav'
rescue LoadError
  # It's OK, we don't include pry in e.g. gemfiles/3.0.gemfile
end

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

def active_record_gem_version
  Gem::Version.new(ActiveRecord::VERSION::STRING)
end

if active_record_gem_version >= Gem::Version.new('5.0.0.beta1')
  # See https://github.com/rails/rails-controller-testing/issues/5
  ActionController::TestCase.send(:include, Rails::Controller::Testing::TestProcess)
end

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
    if respond_to? :use_transactional_tests=
      self.use_transactional_tests = false
    else
      self.use_transactional_fixtures = false
    end
    setup { DatabaseCleaner.start }
  end

  teardown do
    DatabaseCleaner.clean if using_mysql?
    Thread.current[:paper_trail] = nil
  end

  private

  def assert_attributes_equal(expected, actual)
    if using_mysql?
      expected, actual = expected.dup, actual.dup

      # Adjust timestamps for missing fractional seconds precision.
      %w(created_at updated_at).each do |timestamp|
        expected[timestamp] = expected[timestamp].change(usec: 0)
        actual[timestamp]   = actual[timestamp].change(usec: 0)
      end
    end

    assert_equal expected, actual
  end

  def assert_changes_equal(expected, actual)
    if using_mysql?
      expected, actual = expected.dup, actual.dup

      # Adjust timestamps for missing fractional seconds precision.
      %w(created_at updated_at).each do |timestamp|
        expected[timestamp][1] = expected[timestamp][1].change(usec: 0)
        actual[timestamp][1]   = actual[timestamp][1].change(usec: 0)
      end
    end

    assert_equal expected, actual
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

# Wrap args in a hash to support the ActionController::TestCase and
# ActionDispatch::Integration HTTP request method switch to keyword args
# (see https://github.com/rails/rails/blob/master/actionpack/CHANGELOG.md)
def params_wrapper(args)
  if defined?(::Rails) && active_record_gem_version >= Gem::Version.new('5.0.0.beta1')
    { params: args }
  else
    args
  end
end

def reset_version_class_column_info!
  PaperTrail::Version.connection.schema_cache.clear!
  PaperTrail::Version.reset_column_information
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
