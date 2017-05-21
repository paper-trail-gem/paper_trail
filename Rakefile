require "bundler"
Bundler::GemHelper.install_tasks

desc "Set a relevant database.yml for testing"
task :prepare do
  ENV["DB"] ||= "sqlite"
  FileUtils.cp "test/dummy/config/database.#{ENV['DB']}.yml", "test/dummy/config/database.yml"
end

require "rake/testtask"
desc "Run tests on PaperTrail with Test::Unit."
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false

  # Enabling ruby interpreter warnings (-w) is, sadly, impractical. There are
  # too many noisy warnings that we have no control over, e.g. caused by libs we
  # depend on.
  t.warning = false
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
task default: %i(rubocop prepare test spec)
