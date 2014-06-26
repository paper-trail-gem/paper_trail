require 'test_helper'

class PaperTrail::VersionTest < ActiveSupport::TestCase
  setup do
    change_schema
    @animal = Animal.create
    assert PaperTrail::Version.creates.present?
  end

  teardown do
    restore_schema
    Animal.connection.schema_cache.clear!
    Animal.reset_column_information
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

    should "return all versions except create events" do
      PaperTrail::Version.not_creates.each do |version|
        assert_not_equal "create", version.event
      end
    end
  end

  context "PaperTrail::Version.subsequent" do
    setup { 2.times { @animal.update_attributes(:name => Faker::Lorem.word) } }

    context "receiving a TimeStamp" do
      should "return all versions that were created before the Timestamp" do
        value = PaperTrail::Version.subsequent(1.hour.ago, true)
        assert_equal value, @animal.versions.to_a
        assert_not_nil value.to_sql.match(/ORDER BY #{PaperTrail::Version.arel_table[:created_at].asc.to_sql}/)
      end
    end

    context "receiving a `PaperTrail::Version`" do
      should "grab the Timestamp from the version and use that as the value" do
        value = PaperTrail::Version.subsequent(@animal.versions.first)
        assert_equal value, @animal.versions.to_a.tap { |assoc| assoc.shift }
      end
    end
  end

  context "PaperTrail::Version.preceding" do
    setup { 2.times { @animal.update_attributes(:name => Faker::Lorem.word) } }

    context "receiving a TimeStamp" do
      should "return all versions that were created before the Timestamp" do
        value = PaperTrail::Version.preceding(5.seconds.from_now, true)
        assert_equal value, @animal.versions.reverse
        assert_not_nil value.to_sql.match(/ORDER BY #{PaperTrail::Version.arel_table[:created_at].desc.to_sql}/)
      end
    end

    context "receiving a `PaperTrail::Version`" do
      should "grab the Timestamp from the version and use that as the value" do
        value = PaperTrail::Version.preceding(@animal.versions.last)
        assert_equal value, @animal.versions.to_a.tap { |assoc| assoc.pop }.reverse
      end
    end
  end
end
