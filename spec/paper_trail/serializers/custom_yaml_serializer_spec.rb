require "spec_helper"

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
  let(:word_hash) {
    {
      "key1" => ::FFaker::Lorem.word,
      "key2" => nil,
      "tkey" => nil,
      "" => "foo"
    }
  }

  context(".load") do
    it("deserializes YAML to Ruby, removing pairs with blank keys or values") do
      expect(described_class.load(word_hash.to_yaml)).to eq(
        word_hash.reject { |k, v| (k.blank? || v.blank?) }
      )
    end
  end

  context(".dump") do
    it("serializes Ruby to YAML, removing pairs with nil values") do
      expect(described_class.dump(word_hash)).to eq(
        word_hash.reject { |_k, v| v.nil? }.to_yaml
      )
    end
  end
end
