require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
desc 'Run tests on PaperTrail with Test::Unit.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

require 'rspec/core/rake_task'
desc 'Run PaperTrail specs for the RSpec helper.'
RSpec::Core::RakeTask.new(:spec)

desc 'Default: run all available test suites'
task :default => [:test, :spec]
