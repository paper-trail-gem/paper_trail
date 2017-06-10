require "spec_helper"
require_relative "../../support/custom_json_serializer"

RSpec.describe CustomJsonSerializer do
  describe ".load" do
    it "deserializes, removing pairs with blank keys or values" do
      hash = { "key1" => "banana", "tkey" => nil, "" => "foo" }
      expect(described_class.load(hash.to_json)).to(eq("key1" => "banana"))
    end
  end

  describe ".dump" do
    it "serializes to JSON, removing pairs with nil values" do
      hash = { "key1" => "banana", "tkey" => nil, "" => "foo" }
      expect(described_class.dump(hash)).to(eq('{"key1":"banana","":"foo"}'))
    end
  end
end
