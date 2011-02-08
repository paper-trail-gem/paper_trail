$LOAD_PATH.unshift 'lib'
require 'paper_trail/version_number'

Gem::Specification.new do |s|
  s.name             = 'paper_trail'
  s.version          = PaperTrail::VERSION
  s.summary          = "Track changes to your models' data.  Good for auditing or versioning."
  s.description      = s.summary
  s.homepage         = 'http://github.com/airblade/paper_trail'
  s.authors          = ['Andy Stewart']
  s.email            = 'boss@airbladesoftware.com'
  s.files            = %w[ README.md Rakefile paper_trail.gemspec ]
  s.files           += %w[ init.rb install.rb ]
  s.files           += Dir.glob("lib/**/*")
  s.files           += Dir.glob("generators/**/*")
  s.require_path     = 'lib'
  s.test_files       = Dir.glob("test/**/*")

  s.add_development_dependency 'bundler',       '~> 1.0'
  s.add_development_dependency 'rake',          '0.8.7'  # TODO: why do we need to list rake?
  s.add_development_dependency 'shoulda',       '2.10.3'
  s.add_development_dependency 'activesupport', '~> 2.3'
  s.add_development_dependency 'sqlite3-ruby',  '~> 1.2'
  # Repeated here to make bundler happy
  s.add_development_dependency 'activerecord',  '~> 2.3'
  s.add_development_dependency 'actionpack',    '~> 2.3'

  s.add_dependency 'activerecord',  '~> 2.3'
  s.add_dependency 'actionpack',    '~> 2.3'
end
