require 'spec_helper'

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

describe PaperTrail::VersionConcern do
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

describe PaperTrail::Version do
  describe "Attributes" do
    it { should have_db_column(:item_type).of_type(:string) }
    it { should have_db_column(:item_id).of_type(:integer) }
    it { should have_db_column(:event).of_type(:string) }
    it { should have_db_column(:whodunnit).of_type(:string) }
    it { should have_db_column(:object).of_type(:text) }
    it { should have_db_column(:created_at).of_type(:datetime) }
  end

  describe "Indexes" do
    it { should have_db_index([:item_type, :item_id]) }
  end

  describe "Methods" do
    describe "Instance" do
      subject { PaperTrail::Version.new(attributes) rescue PaperTrail::Version.new }

      describe :terminator do
        it { should respond_to(:terminator) }

        let(:attributes) { {:whodunnit => Faker::Name.first_name} }

        it "is an alias for the `whodunnit` attribute" do
          subject.whodunnit.should == attributes[:whodunnit]
        end
      end

      describe :version_author do
        it { should respond_to(:terminator) }

        it "should be an alias for the `terminator` method" do
          subject.method(:version_author).should == subject.method(:terminator)
        end
      end
    end
  end
end
