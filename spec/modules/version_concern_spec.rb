require 'spec_helper'

describe PaperTrail::VersionConcern do

  before(:all) { require 'support/alt_db_init' }

  it 'allows included class to have different connections' do
    Foo::Version.connection.should_not == Bar::Version.connection
  end

  it 'allows custom version class to share connection with superclass' do
    Foo::Version.connection.should == Foo::Document.connection
    Bar::Version.connection.should == Bar::Document.connection
  end

  it 'can be used with class_name option' do
    Foo::Document.version_class_name.should == 'Foo::Version'
    Bar::Document.version_class_name.should == 'Bar::Version'
  end

  describe 'persistence', :versioning => true do
    before do
      @foo_doc = Foo::Document.create!(:name => 'foobar')
      @bar_doc = Bar::Document.create!(:name => 'raboof')
    end

    it 'should store versions in the correct corresponding db location' do
      @foo_doc.versions.first.should be_instance_of(Foo::Version)
      @bar_doc.versions.first.should be_instance_of(Bar::Version)
    end
  end
end
