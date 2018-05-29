# frozen_string_literal: true

require "bundler"
Bundler::GemHelper.install_tasks

desc "Write a database.yml for the specified RDBMS"
task :prepare do
  ENV["DB"] ||= "sqlite"
  FileUtils.cp(
    "spec/dummy_app/config/database.#{ENV['DB']}.yml",
    "spec/dummy_app/config/database.yml"
  )
end

require "rspec/core/rake_task"
desc "Run tests on PaperTrail with RSpec"
task(:spec).clear
RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false # hide list of specs bit.ly/1nVq3Jn
end

require "rubocop/rake_task"
RuboCop::RakeTask.new

desc "Default: run all available test suites"
task default: %i[rubocop prepare spec]
