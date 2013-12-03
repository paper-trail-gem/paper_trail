# This file copies the test database into locations for the `Foo` and `Bar` namespace,
# then defines those namespaces, then establishes the sqlite3 connection for the namespaces
# to simulate an application with multiple database connections.

db_directory = "#{Rails.root}/db"
# setup alternate databases
if RUBY_VERSION.to_f >= 1.9
  FileUtils.cp "#{db_directory}/test.sqlite3", "#{db_directory}/test-foo.sqlite3"
  FileUtils.cp "#{db_directory}/test.sqlite3", "#{db_directory}/test-bar.sqlite3"
else
  require 'ftools'
  File.cp "#{db_directory}/test.sqlite3", "#{db_directory}/test-foo.sqlite3"
  File.cp "#{db_directory}/test.sqlite3", "#{db_directory}/test-bar.sqlite3"
end

module Foo
  class Base < ActiveRecord::Base
    self.abstract_class = true
  end

  class Version < Base
    include PaperTrail::VersionConcern
  end

  class Document < Base
    has_paper_trail :class_name => 'Foo::Version'
  end
end
Foo::Base.establish_connection(:adapter => 'sqlite3', :database => "#{db_directory}/test-foo.sqlite3")

module Bar
  class Base < ActiveRecord::Base
    self.abstract_class = true
  end

  class Version < Base
    include PaperTrail::VersionConcern
  end

  class Document < Base
    has_paper_trail :class_name => 'Bar::Version'
  end
end
Bar::Base.establish_connection(:adapter => 'sqlite3', :database => "#{db_directory}/test-bar.sqlite3")
