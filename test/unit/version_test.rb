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

  context "PaperTrail::Version.where_object" do
    context "receving something other than a Hash as an argument" do
      should "raise an error" do
        assert_raise(ArgumentError) do
          PaperTrail::Version.where_object(:foo)
          PaperTrail::Version.where_object([])
        end
      end
    end
    should "call `where_object` on the serializer" do
      # Create some args to fake-query on.
      args = { :a => 1, :b => '2', :c => false, :d => nil }
      arel_field = PaperTrail::Version.arel_table[:object]

      # Create a dummy value for us to return for each condition that can be
      # chained together with other conditions with Arel's `and`.
      chainable_dummy = arel_field.matches("")

      # Mock a serializer to expect to receive `where_object_condition` with the
      # correct args.
      serializer = MiniTest::Mock.new
      serializer.expect :where_object_condition, chainable_dummy, [arel_field, :a, 1]
      serializer.expect :where_object_condition, chainable_dummy, [arel_field, :b, "2"]
      serializer.expect :where_object_condition, chainable_dummy, [arel_field, :c, false]
      serializer.expect :where_object_condition, chainable_dummy, [arel_field, :d, nil]

      # Stub out PaperTrail.serializer to return our mock, and then make the
      # query call.
      PaperTrail.stub :serializer, serializer do
        PaperTrail::Version.where_object(args)
      end

      # Verify that our serializer mock received the correct
      # `where_object_condition` calls.
      assert serializer.verify
    end
  end
end
