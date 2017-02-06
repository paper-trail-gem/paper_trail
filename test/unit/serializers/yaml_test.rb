require "test_helper"

class YamlTest < ActiveSupport::TestCase
  setup do
    # Setup a hash with random values
    @hash = {}
    (1..4).each do |i|
      @hash["key#{i}".to_sym] = FFaker::Lorem.word
    end
    @hash_as_yaml = @hash.to_yaml
    # Setup an array of random words
    @array = []
    (rand(5) + 4).times { @array << FFaker::Lorem.word }
    @array_as_yaml = @array.to_yaml
  end

  context "`load` class method" do
    should "exist" do
      assert PaperTrail::Serializers::YAML.respond_to?(:load)
    end

    should "deserialize `YAML` to Ruby" do
      assert_equal @hash, PaperTrail::Serializers::YAML.load(@hash_as_yaml)
      assert_equal @array, PaperTrail::Serializers::YAML.load(@array_as_yaml)
    end
  end

  context "`dump` class method" do
    should "exist" do
      assert PaperTrail::Serializers::YAML.respond_to?(:dump)
    end

    should "serialize Ruby to `YAML`" do
      assert_equal @hash_as_yaml, PaperTrail::Serializers::YAML.dump(@hash)
      assert_equal @array_as_yaml, PaperTrail::Serializers::YAML.dump(@array)
    end
  end

  context "`where_object` class method" do
    should "construct correct WHERE query" do
      matches = PaperTrail::Serializers::YAML.where_object_condition(
        PaperTrail::Version.arel_table[:object],
        :arg1,
        "Val 1"
      )
      assert matches.instance_of?(Arel::Nodes::Matches)
      assert_equal matches.right.val, "%\narg1: Val 1\n%"
    end
  end
end
