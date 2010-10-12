$LOAD_PATH.unshift 'lib'
require 'paper_trail/version_number'

require 'rake'
require 'rake/testtask'


desc 'Build the gem.'
task :build do
  sh 'gem build paper_trail.gemspec'
end

desc 'Build and install the gem locally.'
task :install => :build do
  sh "gem install paper_trail-#{PaperTrail::VERSION}.gem"
end

desc 'Tag the code and push tags to origin.'
task :tag do
  sh "git tag v#{PaperTrail::VERSION}"
  sh "git push origin master --tags"
end

desc 'Release gem to rubygems.org.'
task :release => [:build, :tag] do
  sh "gem push paper_trail-#{PaperTrail::VERSION}.gem"
  # sh 'git clean -fd'
end

desc 'Test the paper_trail plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Default: run unit tests.'
task :default => :test
