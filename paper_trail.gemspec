$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
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
  s.homepage = "https://github.com/airblade/paper_trail"
  s.authors = ["Andy Stewart", "Ben Atkins"]
  s.email = "batkinz@gmail.com"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = ">= 2.1.0"

  # Rails does not follow semver, makes breaking changes in minor versions.
  s.add_dependency "activerecord", [">= 4.0", "< 5.2"]
  s.add_dependency "request_store", "~> 1.1"

  s.add_development_dependency "appraisal", "~> 2.1"
  s.add_development_dependency "rake", "~> 10.4.2"
  s.add_development_dependency "shoulda", "~> 3.5.0"
  s.add_development_dependency "ffaker", "~> 2.1.0"

  # Why `railties`? Possibly used by `test/dummy` boot up?
  s.add_development_dependency "railties", [">= 4.0", "< 5.2"]

  s.add_development_dependency "rack-test", "~> 0.6.3"
  s.add_development_dependency "rspec-rails", "~> 3.5"
  s.add_development_dependency "generator_spec", "~> 0.9.3"
  s.add_development_dependency "database_cleaner", "~> 1.2"
  s.add_development_dependency "pry-nav", "~> 0.2.4"
  s.add_development_dependency "rubocop", "~> 0.41.1"
  s.add_development_dependency "rubocop-rspec", "~> 1.5.1"
  s.add_development_dependency "timecop", "~> 0.8.0"
  s.add_development_dependency "sqlite3", "~> 1.2"
  s.add_development_dependency "pg", "~> 0.19.0"
  s.add_development_dependency "mysql2", "~> 0.4.2"
end
