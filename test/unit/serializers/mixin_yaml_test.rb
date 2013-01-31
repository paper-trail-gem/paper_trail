require 'test_helper'

module CustomYamlSerializer
  extend PaperTrail::Serializers::Yaml

  def self.load(string)
    parsed_value = super(string)
    parsed_value.is_a?(Hash) ? parsed_value.reject { |k,v| k.blank? || v.blank? } : parsed_value
  end

  def self.dump(object)
    object.is_a?(Hash) ? super(object.reject { |k,v| v.nil? }) : super
  end
end

class MixinYamlTest < ActiveSupport::TestCase

  setup do
    # Setup a hash with random values, ensuring some values are nil
    @hash = {}
    (1..4).each do |i|
      @hash["key#{i}"] = [Faker::Lorem.word, nil].sample
    end
    @hash['tkey'] = nil
    @hash[''] = 'foo'
    @hash_as_yaml = @hash.to_yaml
  end

  context '`load` class method' do
    should 'exist' do
      assert CustomYamlSerializer.respond_to?(:load)
    end

    should '`deserialize` YAML to Ruby, removing pairs with `blank` keys or values' do
      assert_equal @hash.reject { |k,v| k.blank? || v.blank? }, CustomYamlSerializer.load(@hash_as_yaml)
    end
  end

  context '`dump` class method' do
    should 'exist' do
      assert CustomYamlSerializer.respond_to?(:dump)
    end

    should '`serialize` Ruby to YAML, removing pairs with `nil` values' do
      assert_equal @hash.reject { |k,v| v.nil? }.to_yaml, CustomYamlSerializer.dump(@hash)
    end
  end

end
