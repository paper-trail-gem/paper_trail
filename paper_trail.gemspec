# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "paper_trail/compatibility"
require "paper_trail/version_number"

Gem::Specification.new do |s|
  s.name = "paper_trail"
  s.version = PaperTrail::VERSION::STRING
  s.platform = Gem::Platform::RUBY
  s.summary = "Track changes to your models."
  s.description = <<-EOS
Track changes to your models, for auditing or versioning. See how a model looked
at any stage in its lifecycle, revert it to any version, or restore it after it
has been destroyed.
  EOS
  s.homepage = "https://github.com/paper-trail-gem/paper_trail"
  s.authors = ["Andy Stewart", "Ben Atkins", "Jared Beck"]
  s.email = "jared@jaredbeck.com"
  s.license = "MIT"

  # > Files included in this gem. .. Only add files you can require to this
  # > list, not directories, etc.
  # > https://guides.rubygems.org/specification-reference/#files
  #
  # > Avoid using `git ls-files` to produce lists of files. Downstreams (OS
  # > packagers) often need to build your package in an environment that does
  # > not have git (on purpose).
  # > https://packaging.rubystyle.guide/#using-git-in-gemspec
  #
  # By convention, the `.gemspec` is omitted. Tests and related files (like
  # `Gemfile`) are omitted. Documentation is omitted because it would double
  # gem size. See discussion:
  # https://github.com/paper-trail-gem/paper_trail/pull/1279#pullrequestreview-558840513
  s.files = Dir["lib/**/*", "LICENSE"].reject { |f| File.directory?(f) }

  s.executables = []
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.3.6"

  # PT supports ruby versions until they reach End-of-Life, historically
  # about 3 years, per https://www.ruby-lang.org/en/downloads/branches/
  #
  # See "Lowest supported ruby version" in CONTRIBUTING.md
  s.required_ruby_version = ">= 3.0.0"

  # We no longer specify a maximum activerecord version.
  # See discussion in paper_trail/compatibility.rb
  s.add_dependency "activerecord", ::PaperTrail::Compatibility::ACTIVERECORD_GTE

  # PT supports request_store versions for 3 years.
  s.add_dependency "request_store", "~> 1.4"

  s.add_development_dependency "appraisal", "~> 2.5.0"
  s.add_development_dependency "byebug", "~> 11.1"
  s.add_development_dependency "ffaker", "~> 2.20"
  s.add_development_dependency "generator_spec", "~> 0.9.4"
  s.add_development_dependency "memory_profiler", "~> 1.0.0"

  # For `spec/dummy_app`. Technically, we only need `actionpack` (as of 2020).
  # However, that might change in the future, and the advantages of specifying a
  # subset (e.g. actionpack only) are unclear.
  s.add_development_dependency "rails", ::PaperTrail::Compatibility::ACTIVERECORD_GTE

  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec-rails", "~> 6.0.3"
  s.add_development_dependency "rubocop", "~> 1.22.2"
  s.add_development_dependency "rubocop-packaging", "~> 0.5.1"
  s.add_development_dependency "rubocop-performance", "~> 1.11.5"
  s.add_development_dependency "rubocop-rails", "~> 2.12.4"
  s.add_development_dependency "rubocop-rake", "~> 0.6.0"
  s.add_development_dependency "rubocop-rspec", "~> 2.5.0"
  s.add_development_dependency "simplecov", "~> 0.21.2"

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
  s.add_development_dependency "mysql2", "~> 0.5.3"
  s.add_development_dependency "pg", "~> 1.2"
  s.add_development_dependency "sqlite3", "~> 1.4"
end
