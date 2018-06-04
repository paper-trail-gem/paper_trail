# frozen_string_literal: true

require "fileutils"
require "bundler"
Bundler::GemHelper.install_tasks

desc "Delete generated files and databases"
task :clean do
  # It's tempting to use `git clean` here, but this rake task will be run by
  # people working on changes that haven't been committed yet, so we have to
  # be more selective with what we delete.
  ::FileUtils.rm("spec/dummy_app/db/database.yml", force: true)
  case ENV["DB"]
  when "mysql"
    %w[test foo bar].each do |db|
      system("mysqladmin drop -f paper_trail_#{db} > /dev/null 2>&1")
    end
  when "postgres"
    %w[test foo bar].each do |db|
      system("dropdb --if-exists paper_trail_#{db} > /dev/null 2>&1")
    end
  when nil, "sqlite"
    ::FileUtils.rm(::Dir.glob("spec/dummy_app/db/*.sqlite3"))
  else
    raise "Don't know how to clean specified RDBMS: #{ENV['DB']}"
  end
end

desc "Write a database.yml for the specified RDBMS"
task prepare: [:clean] do
  ENV["DB"] ||= "sqlite"
  FileUtils.cp(
    "spec/dummy_app/config/database.#{ENV['DB']}.yml",
    "spec/dummy_app/config/database.yml"
  )
  case ENV["DB"]
  when "mysql"
    %w[test foo bar].each do |db|
      system("mysqladmin create paper_trail_#{db}")
      # Migration happens later in spec_helper.
    end
  when "postgres"
    %w[test foo bar].each do |db|
      system("createdb paper_trail_#{db}")
      # Migration happens later in spec_helper.
    end
  when nil, "sqlite"
    # noop. test.sqlite3 will be created when migration happens in spec_helper.
    # Shortly thereafter, foo and bar.sqlite3 are created when
    # spec/support/alt_db_init.rb is `require`d.
    nil
  else
    raise "Don't know how to create specified DB: #{ENV['DB']}"
  end
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
