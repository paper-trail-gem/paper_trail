# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["DB"] ||= "sqlite"

require "byebug"

unless File.exist?(File.expand_path("dummy_app/config/database.yml", __dir__))
  warn "WARNING: No database.yml detected for the dummy app, please run `rake prepare` first"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Support for disabling `verify_partial_doubles` on specific examples.
  config.around(:each, verify_stubs: false) do |ex|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = false
      ex.run
      mocks.verify_partial_doubles = true
    end
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = false
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  config.order = :random
  Kernel.srand config.seed
end

def active_record_gem_version
  Gem::Version.new(ActiveRecord::VERSION::STRING)
end

# Wrap args in a hash to support the ActionController::TestCase and
# ActionDispatch::Integration HTTP request method switch to keyword args
# (see https://github.com/rails/rails/blob/master/actionpack/CHANGELOG.md)
def params_wrapper(args)
  if defined?(::Rails) && active_record_gem_version >= Gem::Version.new("5.0.0.beta1")
    { params: args }
  else
    args
  end
end

require File.expand_path("../dummy_app/config/environment", __FILE__)
require "rspec/rails"
require "paper_trail/frameworks/rspec"
require "ffaker"
require "timecop"

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("dummy_app/db/migrate/", __dir__)

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
end

# In rails < 5, some tests seem to require DatabaseCleaner-truncation.
# Truncation is about three times slower than transaction rollback, so it'll
# be nice when we can drop support for rails < 5.
if active_record_gem_version < ::Gem::Version.new("5")
  require "database_cleaner"
  DatabaseCleaner.strategy = :truncation
  RSpec.configure do |config|
    config.use_transactional_fixtures = false
    config.before { DatabaseCleaner.start }
    config.after { DatabaseCleaner.clean }
  end
else
  RSpec.configure do |config|
    config.use_transactional_fixtures = true
  end
end
