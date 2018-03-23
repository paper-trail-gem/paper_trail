# frozen_string_literal: true

require_relative "paper_trail_spec_migrator"

# This file copies the test database into locations for the `Foo` and `Bar`
# namespace, then defines those namespaces, then establishes the sqlite3
# connection for the namespaces to simulate an application with multiple
# database connections.

# Load database yaml to use
configs = YAML.load_file("#{Rails.root}/config/database.yml")

# If we are testing with sqlite make it quick
db_directory = "#{Rails.root}/db"

# Set up alternate databases
if ENV["DB"] == "sqlite"
  FileUtils.cp "#{db_directory}/test.sqlite3", "#{db_directory}/test-foo.sqlite3"
  FileUtils.cp "#{db_directory}/test.sqlite3", "#{db_directory}/test-bar.sqlite3"
end

module Foo
  class Base < ActiveRecord::Base
    self.abstract_class = true
  end

  class Version < Base
    include PaperTrail::VersionConcern
  end

  class Document < Base
    has_paper_trail class_name: "Foo::Version"
  end
end

Foo::Base.configurations = configs
Foo::Base.establish_connection(:foo)
ActiveRecord::Base.establish_connection(:foo)
paper_trail_migrations_path = File.expand_path("#{db_directory}/migrate/", __FILE__)
::PaperTrailSpecMigrator.new(paper_trail_migrations_path).migrate

module Bar
  class Base < ActiveRecord::Base
    self.abstract_class = true
  end

  class Version < Base
    include PaperTrail::VersionConcern
  end

  class Document < Base
    has_paper_trail class_name: "Bar::Version"
  end
end

Bar::Base.configurations = configs
Bar::Base.establish_connection(:bar)
ActiveRecord::Base.establish_connection(:bar)
::PaperTrailSpecMigrator.new(paper_trail_migrations_path).migrate
