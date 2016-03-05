require "test_helper"

module PaperTrail
  class VersionTest < ActiveSupport::TestCase
    setup do
      change_schema
      @animal = Animal.create
      assert Version.creates.present?
    end

    teardown do
      restore_schema
      Animal.connection.schema_cache.clear!
      Animal.reset_column_information
    end

    context ".creates" do
      should "return only create events" do
        Version.creates.each do |version|
          assert_equal "create", version.event
        end
      end
    end

    context ".updates" do
      setup {
        @animal.update_attributes(name: "Animal")
        assert Version.updates.present?
      }

      should "return only update events" do
        Version.updates.each do |version|
          assert_equal "update", version.event
        end
      end
    end

    context ".destroys" do
      setup {
        @animal.destroy
        assert Version.destroys.present?
      }

      should "return only destroy events" do
        Version.destroys.each do |version|
          assert_equal "destroy", version.event
        end
      end
    end

    context ".not_creates" do
      setup {
        @animal.update_attributes(name: "Animal")
        @animal.destroy
        assert Version.not_creates.present?
      }

      should "return all versions except create events" do
        Version.not_creates.each do |version|
          assert_not_equal "create", version.event
        end
      end
    end

    context ".subsequent" do
      setup do
        2.times do
          @animal.update_attributes(name: FFaker::Lorem.word)
        end
      end

      context "given a timestamp" do
        should "return all versions that were created after the timestamp" do
          value = Version.subsequent(1.hour.ago, true)
          assert_equal @animal.versions.to_a, value
          assert_match(
            /ORDER BY #{Version.arel_table[:created_at].asc.to_sql}/,
            value.to_sql
          )
        end
      end

      context "given a Version" do
        should "grab the timestamp from the version and use that as the value" do
          expected = @animal.versions.to_a.tap(&:shift)
          actual = Version.subsequent(@animal.versions.first)
          assert_equal expected, actual
        end
      end
    end

    context ".preceding" do
      setup do
        2.times do
          @animal.update_attributes(name: FFaker::Lorem.word)
        end
      end

      context "given a timestamp" do
        should "return all versions that were created before the timestamp" do
          value = Version.preceding(5.seconds.from_now, true)
          assert_equal @animal.versions.reverse, value
          assert_match(
            /ORDER BY #{Version.arel_table[:created_at].desc.to_sql}/,
            value.to_sql
          )
        end
      end

      context "given a Version" do
        should "grab the timestamp from the version and use that as the value" do
          expected = @animal.versions.to_a.tap(&:pop).reverse
          actual = Version.preceding(@animal.versions.last)
          assert_equal expected, actual
        end
      end
    end
  end
end
