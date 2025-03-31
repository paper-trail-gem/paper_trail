# frozen_string_literal: true

require "spec_helper"

module CustomYamlSerializer
  extend PaperTrail::Serializers::YAML

  def self.load(string)
    parsed_value = super
    if parsed_value.is_a?(Hash)
      parsed_value.reject { |k, v| k.blank? || v.blank? }
    else
      parsed_value
    end
  end

  def self.dump(object)
    object.is_a?(Hash) ? super(object.compact) : super
  end
end

RSpec.describe CustomYamlSerializer do
  let(:word_hash) {
    {
      "key1" => FFaker::Lorem.word,
      "key2" => nil,
      "tkey" => nil,
      "" => "foo"
    }
  }

  describe ".load" do
    it("deserializes YAML to Ruby, removing pairs with blank keys or values") do
      expect(described_class.load(word_hash.to_yaml)).to eq(
        word_hash.reject { |k, v| k.blank? || v.blank? }
      )
    end
  end

  describe ".dump" do
    it("serializes Ruby to YAML, removing pairs with nil values") do
      expect(described_class.dump(word_hash)).to eq(
        word_hash.compact.to_yaml
      )
    end
  end
end
