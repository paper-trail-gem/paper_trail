require "pry"

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
  # config.order = :random
  # Kernel.srand config.seed
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
