require 'test_helper'

class PaperTrail::VersionTest < ActiveSupport::TestCase
  setup do
    change_schema
    @animal = Animal.create
    assert PaperTrail::Version.creates.present?
  end

  context "PaperTrail::Version.creates" do
    should "return only create events" do
      PaperTrail::Version.creates.each do |version|
        assert_equal "create", version.event
      end
    end
  end

  context "PaperTrail::Version.updates" do
    setup {
      @animal.update_attributes(:name => 'Animal')
      assert PaperTrail::Version.updates.present?
    }

    should "return only update events" do
      PaperTrail::Version.updates.each do |version|
        assert_equal "update", version.event
      end
    end
  end

  context "PaperTrail::Version.destroys" do
    setup {
      @animal.destroy
      assert PaperTrail::Version.destroys.present?
    }

    should "return only destroy events" do
      PaperTrail::Version.destroys.each do |version|
        assert_equal "destroy", version.event
      end
    end
  end

  context "PaperTrail::Version.not_creates" do
    setup {
      @animal.update_attributes(:name => 'Animal')
      @animal.destroy
      assert PaperTrail::Version.not_creates.present?
    }

    should "return all items except create events" do
      PaperTrail::Version.not_creates.each do |version|
        assert_not_equal "create", version.event
      end
    end
  end
end

class VersionTest < ActiveSupport::TestCase
  # without this, it sometimes picks up the changed schema from the previous test and gets confused
  setup { PaperTrail::Version.reset_column_information }

  context "Version class" do
    should "be a subclass of the `PaperTrail::Version` class" do
      assert Version < PaperTrail::Version
    end

    should "act like a `PaperTrail::Version` while warning the user" do
      widget = Widget.create! :name => Faker::Name.name
      widget.update_attributes! :name => Faker::Name.name
      assert_equal Version.last.reify.name, widget.versions.last.reify.name
    end
  end
end
