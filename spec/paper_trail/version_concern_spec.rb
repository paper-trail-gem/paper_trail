require "spec_helper"
require "support/alt_db_init"

RSpec.describe PaperTrail::VersionConcern do
  it "allows included class to have different connections" do
    expect(Foo::Version.connection).not_to eq(Bar::Version.connection)
  end

  it "allows custom version class to share connection with superclass" do
    expect(Foo::Version.connection).to eq(Foo::Document.connection)
    expect(Bar::Version.connection).to eq(Bar::Document.connection)
  end

  it "can be used with class_name option" do
    expect(Foo::Document.version_class_name).to eq("Foo::Version")
    expect(Bar::Document.version_class_name).to eq("Bar::Version")
  end

  describe "persistence", versioning: true do
    it "stores versions in the correct corresponding db location" do
      foo_doc = Foo::Document.create!(name: "foobar")
      bar_doc = Bar::Document.create!(name: "raboof")
      expect(foo_doc.versions.first).to be_instance_of(Foo::Version)
      expect(bar_doc.versions.first).to be_instance_of(Bar::Version)
    end
  end
end
