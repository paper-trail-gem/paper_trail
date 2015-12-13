$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'paper_trail/version_number'

Gem::Specification.new do |s|
  s.name          = 'paper_trail'
  s.version       = PaperTrail.version
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Track changes to your models' data. Good for auditing or versioning."
  s.description   = s.summary
  s.homepage      = 'https://github.com/airblade/paper_trail'
  s.authors       = ['Andy Stewart', 'Ben Atkins']
  s.email         = 'batkinz@gmail.com'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.3.6'
  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'activerecord', ['>= 3.0', '< 6.0']
  s.add_dependency 'activesupport', ['>= 3.0', '< 6.0']
  s.add_dependency 'request_store', '~> 1.1'

  s.add_development_dependency 'rake', '~> 10.1.1'
  s.add_development_dependency 'shoulda', '~> 3.5'
  # s.add_development_dependency 'shoulda-matchers', '~> 1.5' # needed for ActiveRecord < 4
  s.add_development_dependency 'ffaker', '<= 1.31.0'
  s.add_development_dependency 'railties', ['>= 3.0', '< 5.0']
  s.add_development_dependency 'sinatra', '~> 1.0'
  s.add_development_dependency 'rack-test', '>= 0.6'
  s.add_development_dependency 'rspec-rails', '~> 3.1.0'
  s.add_development_dependency 'generator_spec'
  s.add_development_dependency 'database_cleaner', '~> 1.2'
  s.add_development_dependency 'pry-nav', '~> 0.2.4'
  s.add_development_dependency 'rubocop', '~> 0.35.1'

  # Allow time travel in testing. timecop is only supported after 1.9.2 but
  # does a better cleanup at 'return'.
  # TODO: We can remove delorean, as we no longer support ruby < 1.9.3
  if RUBY_VERSION < "1.9.2"
    s.add_development_dependency 'delorean'
  else
    s.add_development_dependency 'timecop'
  end

  # JRuby support for the test ENV
  unless defined?(JRUBY_VERSION)
    s.add_development_dependency 'sqlite3', '~> 1.2'

    # We would prefer to only constrain mysql2 to '~> 0.3',
    # but a rails bug (https://github.com/rails/rails/issues/21544)
    # requires us to constrain to '~> 0.3.20' for now.
    s.add_development_dependency 'mysql2', '~> 0.3.20'

    s.add_development_dependency 'pg', '~> 0.17'
  else
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', '~> 1.3'
    s.add_development_dependency 'activerecord-jdbcpostgresql-adapter', '~> 1.3'
    s.add_development_dependency 'activerecord-jdbcmysql-adapter', '~> 1.3'
  end
end
