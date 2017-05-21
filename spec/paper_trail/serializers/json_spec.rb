require "rails_helper"

module PaperTrail
  module Serializers
    ::RSpec.describe JSON do
      let(:word_hash) {
        (1..4).each_with_object({}) { |i, a| a["key#{i}"] = ::FFaker::Lorem.word }
      }
      let(:word_array) { [].fill(0, rand(5) + 4) { ::FFaker::Lorem.word } }

      describe ".load" do
        it "deserialize JSON to Ruby" do
          expect(described_class.load(word_hash.to_json)).to eq(word_hash)
          expect(described_class.load(word_array.to_json)).to eq(word_array)
        end
      end

      describe ".dump" do
        it "serializes Ruby to JSON" do
          expect(described_class.dump(word_hash)).to eq(word_hash.to_json)
          expect(described_class.dump(word_array)).to eq(word_array.to_json)
        end
      end

      describe ".where_object_condition" do
        context "when value is a string" do
          it "construct correct WHERE query" do
            matches = described_class.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, "Val 1")
            expect(matches.instance_of?(Arel::Nodes::Matches)).to(eq(true))
            expect(matches.right.val).to eq("%\"arg1\":\"Val 1\"%")
          end
        end

        context "when value is null" do
          it "construct correct WHERE query" do
            matches = described_class.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, nil)
            expect(matches.instance_of?(Arel::Nodes::Matches)).to(eq(true))
            expect(matches.right.val).to(eq("%\"arg1\":null%"))
          end
        end

        context "when value is a number" do
          it "construct correct WHERE query" do
            grouping = described_class.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, -3.5)
            expect(grouping.instance_of?(Arel::Nodes::Grouping)).to(eq(true))
            matches = grouping.select { |v| v.instance_of?(Arel::Nodes::Matches) }
            expect(matches.first.right.val).to eq("%\"arg1\":-3.5,%")
            expect(matches.last.right.val).to eq("%\"arg1\":-3.5}%")
          end
        end
      end
    end
  end
end
