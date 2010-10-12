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

  s.add_dependency 'activerecord'
  s.add_dependency 'actionpack'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'activesupport'
end
