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

  s.files = `git ls-files -z`.split("\x0").select { |f|
    f.match(%r{^(Gemfile|LICENSE|lib|paper_trail.gemspec)/})
  }
  s.executables = []
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = ">= 2.3.0"

  # We no longer specify a maximum rails version.
  # See discussion in paper_trail/compatibility.rb
  s.add_dependency "activerecord", ::PaperTrail::Compatibility::ACTIVERECORD_GTE
  s.add_dependency "request_store", "~> 1.1"

  s.add_development_dependency "appraisal", "~> 2.2"
  s.add_development_dependency "byebug", "~> 11.0"
  s.add_development_dependency "ffaker", "~> 2.11"
  s.add_development_dependency "generator_spec", "~> 0.9.4"
  s.add_development_dependency "memory_profiler", "~> 0.9.14"
  s.add_development_dependency "paper_trail-association_tracking", "~> 2.0.0"
  s.add_development_dependency "rake", "~> 12.3"
  s.add_development_dependency "rspec-rails", "~> 3.8"
  s.add_development_dependency "rubocop", "~> 0.74.0"
  s.add_development_dependency "rubocop-performance", "~> 1.4"
  s.add_development_dependency "rubocop-rspec", "~> 1.35"

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
  s.add_development_dependency "mysql2", ">= 0.4.4"
  s.add_development_dependency "pg", ">= 0.18", "< 2.0"
  s.add_development_dependency "sqlite3", "~> 1.4"
end
