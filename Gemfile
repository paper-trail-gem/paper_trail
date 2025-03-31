# frozen_string_literal: true

source "https://rubygems.org"
gemspec

# The following gems have been extracted from the Ruby stdlib to gems, and we
# must manually include them here in order for specs to run.
gem "benchmark", "~> 0.4.0"
gem "bigdecimal", "~> 3.1"
gem "drb", "~> 2.2"
gem "logger", "~> 1.6"
gem "mutex_m", "~> 0.3.0"

gem "appraisal", "~> 2.5"
gem "byebug", "~> 11.1"
gem "ffaker", "~> 2.20"
gem "generator_spec", "~> 0.9.4"
gem "memory_profiler", "~> 1.0.0"

gem "rake", "~> 13.0"
gem "rspec-rails", "~> 6.0.3"
gem "rubocop", "~> 1.75"
gem "rubocop-packaging", "~> 0.6.0"
gem "rubocop-performance", "~> 1.24.0"
gem "rubocop-rails", "~> 2.30.3"
gem "rubocop-rake", "~> 0.7.1"
gem "rubocop-rspec", "~> 2.17.0"
gem "simplecov", "~> 0.21.2"

# ## Database Adapters
#
# The dependencies here must match the `gem` call at the top of their
# adapters, eg. `active_record/connection_adapters/mysql2_adapter.rb`,
# assuming said call is consistent for all versions of rails we test against
# (see `Appraisals`).
#
# Currently, all versions of rails we test against are consistent. In the past,
# when we tested against rails 4.2, we had to specify database adapters in
# `Appraisals`.
gem "mysql2", "~> 0.5.3"
gem "pg", "~> 1.2"
gem "sqlite3", "~> 1.4"
