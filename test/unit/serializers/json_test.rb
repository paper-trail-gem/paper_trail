require 'test_helper'

class JsonTest < ActiveSupport::TestCase

  setup do
    # Setup a hash with random values
    @hash = {}
    (1..4).each do |i|
      @hash["key#{i}"] = Faker::Lorem.word
    end
    @hash_as_json = @hash.to_json
    # Setup an array of random words
    @array = []
    (4..8).to_a.sample.times do
      @array << Faker::Lorem.word
    end
    @array_as_json = @array.to_json
  end

  context '`load` class method' do
    should 'exist' do
      assert PaperTrail::Serializers::Json.respond_to?(:load)
    end

    should '`deserialize` JSON to Ruby' do
      assert_equal @hash, PaperTrail::Serializers::Json.load(@hash_as_json)
      assert_equal @array, PaperTrail::Serializers::Json.load(@array_as_json)
    end
  end

  context '`dump` class method' do
    should 'exist' do
      assert PaperTrail::Serializers::Json.respond_to?(:dump)
    end

    should '`deserialize` JSON to Ruby' do
      assert_equal @hash_as_json, PaperTrail::Serializers::Json.dump(@hash)
      assert_equal @array_as_json, PaperTrail::Serializers::Json.dump(@array)
    end
  end

end
