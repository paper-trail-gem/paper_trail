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

desc 'Run all available test suites'
task :run_all_tests do
  system('rake test')
  system('rake spec')
end

desc 'Default: run unit tests.'
task :default => :run_all_tests
