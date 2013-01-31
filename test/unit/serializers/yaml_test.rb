require 'test_helper'

class YamlTest < ActiveSupport::TestCase

  setup do
    # Setup a hash with random values
    @hash = {}
    (1..4).each do |i|
      @hash["key#{i}".to_sym] = Faker::Lorem.word
    end
    @hash_as_yaml = @hash.to_yaml
    # Setup an array of random words
    @array = []
    (rand(5) + 4).times { @array << Faker::Lorem.word }
    @array_as_yaml = @array.to_yaml
  end

  context '`load` class method' do
    should 'exist' do
      assert PaperTrail::Serializers::Yaml.respond_to?(:load)
    end

    should '`deserialize` YAML to Ruby' do
      assert_equal @hash, PaperTrail::Serializers::Yaml.load(@hash_as_yaml)
      assert_equal @array, PaperTrail::Serializers::Yaml.load(@array_as_yaml)
    end
  end

  context '`dump` class method' do
    should 'exist' do
      assert PaperTrail::Serializers::Yaml.respond_to?(:dump)
    end

    should '`serialize` Ruby to YAML' do
      assert_equal @hash_as_yaml, PaperTrail::Serializers::Yaml.dump(@hash)
      assert_equal @array_as_yaml, PaperTrail::Serializers::Yaml.dump(@array)
    end
  end

end
