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

  context "Version.not_creates" do
    setup {
      @article.update_attributes(:name => 'Animal')
      @article.destroy
      assert Version.not_creates.present?
    }

    should "return all items except create events" do
      Version.not_creates.each do |version|
        assert_not_equal "create", version.event
      end
    end
  end
end
