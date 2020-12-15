# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["DB"] ||= "sqlite"

require "byebug"
require_relative "support/pt_arel_helpers"

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
  config.include PTArelHelpers
  Kernel.srand config.seed
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
