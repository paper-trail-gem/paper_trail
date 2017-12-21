# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Serializers
    ::RSpec.describe(YAML, versioning: true) do
      let(:array) { ::Array.new(10) { ::FFaker::Lorem.word } }
      let(:hash) {
        {
          alice: "bob",
          binary: 0xdeadbeef,
          octal_james_bond: 0o7,
          int: 42,
          float: 4.2
        }
      }

      describe ".load" do
        it "deserializes YAML to Ruby" do
          expect(described_class.load(hash.to_yaml)).to eq(hash)
          expect(described_class.load(array.to_yaml)).to eq(array)
        end
      end

      describe ".dump" do
        it "serializes Ruby to YAML" do
          expect(described_class.dump(hash)).to eq(hash.to_yaml)
          expect(described_class.dump(array)).to eq(array.to_yaml)
        end
      end

      describe ".where_object" do
        it "constructs the correct WHERE query" do
          matches = described_class.where_object_condition(
            ::PaperTrail::Version.arel_table[:object], :arg1, "Val 1"
          )
          expect(matches.instance_of?(Arel::Nodes::Matches)).to(eq(true))
          expect(matches.right.val).to eq("%\narg1: Val 1\n%")
        end
      end
    end
  end
end
