require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

desc 'Test the paper_trail plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

desc 'Default: run unit tests.'
task :default => :test
