require 'test_helper'

class JSONTest < ActiveSupport::TestCase

  setup do
    # Setup a hash with random values
    @hash = {}
    (1..4).each do |i|
      @hash["key#{i}"] = Faker::Lorem.word
    end
    @hash_as_json = @hash.to_json
    # Setup an array of random words
    @array = []
    (rand(5) + 4).times { @array << Faker::Lorem.word }
    @array_as_json = @array.to_json
  end

  context '`load` class method' do
    should 'exist' do
      assert PaperTrail::Serializers::JSON.respond_to?(:load)
    end

    should '`deserialize` JSON to Ruby' do
      assert_equal @hash, PaperTrail::Serializers::JSON.load(@hash_as_json)
      assert_equal @array, PaperTrail::Serializers::JSON.load(@array_as_json)
    end
  end

  context '`dump` class method' do
    should 'exist' do
      assert PaperTrail::Serializers::JSON.respond_to?(:dump)
    end

    should '`serialize` Ruby to JSON' do
      assert_equal @hash_as_json, PaperTrail::Serializers::JSON.dump(@hash)
      assert_equal @array_as_json, PaperTrail::Serializers::JSON.dump(@array)
    end
  end

  context '`where_object` class method' do
    context "when value is a string" do
      should 'construct correct WHERE query' do
        matches = PaperTrail::Serializers::JSON.where_object_condition(
          PaperTrail::Version.arel_table[:object], :arg1, "Val 1")

        assert matches.instance_of?(Arel::Nodes::Matches)
        if Arel::VERSION >= '6'
          assert_equal matches.right.val, "%\"arg1\":\"Val 1\"%"
        else
          assert_equal matches.right, "%\"arg1\":\"Val 1\"%"
        end
      end
    end

    context "when value is `null`" do
      should 'construct correct WHERE query' do
        matches = PaperTrail::Serializers::JSON.where_object_condition(
          PaperTrail::Version.arel_table[:object], :arg1, nil)

        assert matches.instance_of?(Arel::Nodes::Matches)
        if Arel::VERSION >= '6'
          assert_equal matches.right.val, "%\"arg1\":null%"
        else
          assert_equal matches.right, "%\"arg1\":null%"
        end
      end
    end

    context "when value is a number" do
      should 'construct correct WHERE query' do
        grouping = PaperTrail::Serializers::JSON.where_object_condition(
          PaperTrail::Version.arel_table[:object], :arg1, -3.5)

        assert grouping.instance_of?(Arel::Nodes::Grouping)
        matches = grouping.select { |v| v.instance_of?(Arel::Nodes::Matches) }
        # Numeric arguments need to ensure that they match for only the number, not the beginning 
        # of a #, so it uses an Grouping matcher (See notes on `PaperTrail::Serializers::JSON`)
        if Arel::VERSION >= '6'
          assert_equal matches.first.right.val, "%\"arg1\":-3.5,%"
          assert_equal matches.last.right.val, "%\"arg1\":-3.5}%"
        else
          assert_equal matches.first.right, "%\"arg1\":-3.5,%"
          assert_equal matches.last.right, "%\"arg1\":-3.5}%"
        end
      end
    end
  end
end
