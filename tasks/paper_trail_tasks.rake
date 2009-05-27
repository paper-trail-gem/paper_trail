require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'paper_trail'
    gemspec.summary = "Track changes to your models' data.  Good for auditing or versioning."
    gemspec.email = 'boss@airbladesoftware.com'
    gemspec.homepage = 'http://github.com/airblade/paper_trail'
    gemspec.authors = ['Andy Stewart']
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

