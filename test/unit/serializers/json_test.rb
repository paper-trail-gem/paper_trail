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
        sql = PaperTrail::Serializers::JSON.where_object_condition(
          PaperTrail::Version.arel_table[:object], :arg1, "Val 1").
          to_sql

        assert sql.include?("LIKE '%\"arg1\":\"Val 1\"%'")
      end
    end

    context "when value is `null`" do
      should 'construct correct WHERE query' do
        sql = PaperTrail::Serializers::JSON.where_object_condition(
          PaperTrail::Version.arel_table[:object], :arg1, nil).
          to_sql

        assert sql.include?("LIKE '%\"arg1\":null%'")
      end
    end

    context "when value is a number" do
      should 'construct correct WHERE query' do
        sql = PaperTrail::Serializers::JSON.where_object_condition(
          PaperTrail::Version.arel_table[:object], :arg1, -3.5).
          to_sql

        assert_equal sql,
          "(\"versions\".\"object\" LIKE '%\"arg1\":-3.5,%' OR "\
            "\"versions\".\"object\" LIKE '%\"arg1\":-3.5}%')"
      end
    end
  end
end
