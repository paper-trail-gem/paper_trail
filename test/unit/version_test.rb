require 'test_helper'

class VersionTest < ActiveSupport::TestCase
  setup {
    change_schema
    @article = Animal.create
    assert Version.creates.present?
  }

  context "Version.creates" do
    should "return only create events" do
      Version.creates.each do |version|
        assert_equal "create", version.event
      end
    end
  end

  context "Version.updates" do
    setup {
      @article.update_attributes(:name => 'Animal')
      assert Version.updates.present?
    }

    should "return only update events" do
      Version.updates.each do |version|
        assert_equal "update", version.event
      end
    end
  end

  context "Version.destroys" do
    setup {
      @article.destroy
      assert Version.destroys.present?
    }

    should "return only destroy events" do
      Version.destroys.each do |version|
        assert_equal "destroy", version.event
      end
    end
  end
end
