# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["DB"] ||= "sqlite"

require "simplecov"
SimpleCov.start do
  add_filter %w[Appraisals Gemfile Rakefile doc gemfiles spec]
end
SimpleCov.minimum_coverage(ENV["DB"] == "postgres" ? 96.71 : 92.4)

require "byebug"
require_relative "support/pt_arel_helpers"

unless ENV["BUNDLE_GEMFILE"].match?(/rails_\d\.\d\.gemfile/)
  warn(
    "It looks like you're trying to run the PT test suite, but you're not " \
    'using appraisal. Please see "Development" in CONTRIBUTING.md.'
  )
  exit 1
end
unless File.exist?(File.expand_path("dummy_app/config/database.yml", __dir__))
  warn "No database.yml detected for the dummy app, please run `rake install_database_yml` first"
  exit 1
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

# At this point, totally isolated unit tests could be run. But the PT test suite
# also has "integration" tests, via a "dummy" Rails app. Here, we boot that
# "dummy" app. The following process follows the same order, roughly, as a
# conventional Rails app.
#
# In the past, this boot process was partially implemented here, and partially
# in `dummy_app/config/*`. By consolidating it here,
#
# - It can better be understood, and documented in one place
# - It can more closely resemble a conventional app boot. For example, loading
# gems (like rspec-rails) _before_ loading the app.

# First, `config/boot.rb` would add gems to $LOAD_PATH.
Bundler.setup

# Then, the chosen components of Rails would be loaded. In our case, we only
# test with AR and AC. We require `logger` because `active_record` needs it.
require "logger"
require "active_record/railtie"
require "action_controller/railtie"

# Then, gems are loaded. In a conventional Rails app, this would be done with
# by the `Bundler.require` in `config/application.rb`.
require "paper_trail"
require "ffaker"
require "n_plus_one_control/rspec"
require "rspec/rails"
require "rails-controller-testing"

# Now we can load our dummy app. Its boot process does not perfectly match a
# conventional Rails app, but it's what we were able to fit in our test suite.
require File.expand_path("dummy_app/config/environment", __dir__)

# Now that AR has a connection pool, we can migrate the database.
require_relative "support/paper_trail_spec_migrator"
PaperTrailSpecMigrator.new.migrate

# This final section resembles what might be dummy_app's spec_helper, if it
# had one.
require "paper_trail/frameworks/rspec"
RSpec.configure do |config|
  config.fixture_path = nil # we use factories, not fixtures
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
end
