$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'paper_trail/version_number'

Gem::Specification.new do |s|
  s.name          = 'paper_trail'
  s.version       = PaperTrail::VERSION
  s.summary       = "Track changes to your models' data.  Good for auditing or versioning."
  s.description   = s.summary
  s.homepage      = 'http://github.com/airblade/paper_trail'
  s.authors       = ['Andy Stewart']
  s.email         = 'boss@airbladesoftware.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'railties', '~> 3.0'
  s.add_dependency 'activerecord', '~> 3.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'shoulda', '~> 3.3'
  s.add_development_dependency 'shoulda-matchers', '~> 1.5'
  s.add_development_dependency 'ffaker',  '>= 1.15'
  # JRuby support for the test ENV
  unless defined?(JRUBY_VERSION)
    s.add_development_dependency 'sqlite3', '~> 1.2'
  else
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', '~> 1.2.9'
  end
end
