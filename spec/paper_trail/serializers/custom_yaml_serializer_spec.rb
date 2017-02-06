require "rails_helper"

module CustomYamlSerializer
  extend PaperTrail::Serializers::YAML

  def self.load(string)
    parsed_value = super(string)
    if parsed_value.is_a?(Hash)
      parsed_value.reject { |k, v| (k.blank? || v.blank?) }
    else
      parsed_value
    end
  end

  def self.dump(object)
    object.is_a?(Hash) ? super(object.reject { |_k, v| v.nil? }) : super
  end
end

RSpec.describe CustomYamlSerializer do
  before do
    @hash = {}
    (1..4).each { |i| @hash["key#{i}"] = [FFaker::Lorem.word, nil].sample }
    @hash["tkey"] = nil
    @hash[""] = "foo"
    @hash_as_yaml = @hash.to_yaml
  end

  context(".load") do
    it("deserializes YAML to Ruby, removing pairs with blank keys or values") do
      expect(CustomYamlSerializer.load(@hash_as_yaml)).to eq(
        @hash.reject { |k, v| (k.blank? || v.blank?) }
      )
    end
  end

  context(".dump") do
    it("serializes Ruby to YAML, removing pairs with nil values") do
      expect(CustomYamlSerializer.dump(@hash)).to eq(
        @hash.reject { |_k, v| v.nil? }.to_yaml
      )
    end
  end
end
