require 'test_helper'

class VersionTest < ActiveSupport::TestCase
  setup {
    change_schema
    @article = Animal.create
    assert PaperTrail::Version.creates.present?
  }

  context "PaperTrail::Version.creates" do
    should "return only create events" do
      PaperTrail::Version.creates.each do |version|
        assert_equal "create", version.event
      end
    end
  end

  context "PaperTrail::Version.updates" do
    setup {
      @article.update_attributes(:name => 'Animal')
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
      @article.destroy
      assert PaperTrail::Version.destroys.present?
    }

    should "return only destroy events" do
      PaperTrail::Version.destroys.each do |version|
        assert_equal "destroy", version.event
      end
    end
  end
end
