require 'spec_helper'

describe PaperTrail::VersionConcern do

  before(:all) do
    module Foo
      class Base < ActiveRecord::Base
        self.abstract_class = true
      end

      class Document < Base
        has_paper_trail :class_name => 'Foo::Version'
      end

      class Version < Base
        include PaperTrail::VersionConcern
      end
    end
    Foo::Base.establish_connection(:adapter => 'sqlite3', :database => File.expand_path('../../../test/dummy/db/test-foo.sqlite3', __FILE__))

    module Bar
      class Base < ActiveRecord::Base
        self.abstract_class = true
      end

      class Document < Base
        has_paper_trail :class_name => 'Bar::Version'
      end

      class Version < Base
        include PaperTrail::VersionConcern
      end
    end
    Bar::Base.establish_connection(:adapter => 'sqlite3', :database => File.expand_path('../../../test/dummy/db/test-bar.sqlite3', __FILE__))
  end

  it 'allows included class to have different connections' do
    Foo::Version.connection.should_not eq Bar::Version.connection
  end

  it 'allows custom version class to share connection with superclass' do
    Foo::Version.connection.should eq Foo::Document.connection
    Bar::Version.connection.should eq Bar::Document.connection
  end

  it 'can be used with class_name option' do
    Foo::Document.version_class_name.should eq 'Foo::Version'
    Bar::Document.version_class_name.should eq 'Bar::Version'
  end
end
