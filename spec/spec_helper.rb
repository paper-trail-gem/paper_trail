# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["DB"] ||= "sqlite"

require "byebug"

unless File.exist?(File.expand_path("dummy_app/config/database.yml", __dir__))
  warn "No database.yml detected for the dummy app, please run `rake prepare` first"
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_results"
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
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

# At the time rails 5.0 introduced the `params` keyword for controller tests,
# we still supported rails 4, so we needed a method here to handle both
# versions. We no longer need this method.
def params_wrapper(args)
  ActiveSupport::Deprecation.warn("In PT tests, do not use params_wrapper anymore")
  { params: args }
end

require File.expand_path("dummy_app/config/environment", __dir__)
require "rspec/rails"
require "paper_trail/frameworks/rspec"
require "ffaker"

# Migrate
require_relative "support/paper_trail_spec_migrator"
::PaperTrailSpecMigrator.new.migrate

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
end
