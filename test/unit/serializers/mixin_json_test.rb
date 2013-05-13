require 'test_helper'
require 'custom_json_serializer'

class MixinJsonTest < ActiveSupport::TestCase

  setup do
    # Setup a hash with random values, ensuring some values are nil
    @hash = {}
    (1..4).each do |i|
      @hash["key#{i}"] = [Faker::Lorem.word, nil].sample
    end
    @hash['tkey'] = nil
    @hash[''] = 'foo'
    @hash_as_json = @hash.to_json
  end

  context '`load` class method' do
    should 'exist' do
      assert CustomJsonSerializer.respond_to?(:load)
    end

    should '`deserialize` JSON to Ruby, removing pairs with `blank` keys or values' do
      assert_equal @hash.reject { |k,v| k.blank? || v.blank? }, CustomJsonSerializer.load(@hash_as_json)
    end
  end

  context '`dump` class method' do
    should 'exist' do
      assert CustomJsonSerializer.respond_to?(:dump)
    end

    should '`serialize` Ruby to JSON, removing pairs with `nil` values' do
      assert_equal @hash.reject { |k,v| v.nil? }.to_json, CustomJsonSerializer.dump(@hash)
    end
  end
end
