# frozen_string_literal: true

ENV["DB"] ||= "sqlite"

require "fileutils"
require "bundler"
Bundler::GemHelper.install_tasks

desc "Copy the database.DB.yml per ENV['DB']"
task :install_database_yml do
  puts format("installing database.yml for %s", ENV["DB"])

  # It's tempting to use `git clean` here, but this rake task will be run by
  # people working on changes that haven't been committed yet, so we have to
  # be more selective with what we delete.
  FileUtils.rm("spec/dummy_app/db/database.yml", force: true)

  FileUtils.cp(
    "spec/dummy_app/config/database.#{ENV['DB']}.yml",
    "spec/dummy_app/config/database.yml"
  )
end

desc "Delete generated files and databases"
task :clean do
  puts format("dropping %s database", ENV["DB"])
  case ENV["DB"]
  when "mysql"
    # TODO: only works locally. doesn't respect database.yml
    system "mysqladmin drop -f paper_trail_test > /dev/null 2>&1"
  when "postgres"
    # TODO: only works locally. doesn't respect database.yml
    system "dropdb --if-exists paper_trail_test > /dev/null 2>&1"
  when nil, "sqlite"
    FileUtils.rm(Dir.glob("spec/dummy_app/db/*.sqlite3"))
  else
    raise "Don't know how to clean specified RDBMS: #{ENV['DB']}"
  end
end

desc "Create the database."
task :create_db do
  puts format("creating %s database", ENV["DB"])
  case ENV["DB"]
  when "mysql"
    # TODO: only works locally. doesn't respect database.yml
    system "mysqladmin create paper_trail_test"
  when "postgres"
    # TODO: only works locally. doesn't respect database.yml
    system "createdb paper_trail_test"
  when nil, "sqlite"
    # noop. test.sqlite3 will be created when migration happens
    nil
  else
    raise "Don't know how to create specified DB: #{ENV['DB']}"
  end
end

desc <<~EOS
  Write a database.yml for the specified RDBMS, and create database. Does not
  migrate. Migration happens later in spec_helper.
EOS
task prepare: %i[clean install_database_yml create_db]

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
