# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Serializers
    ::RSpec.describe JSON do
      let(:word_hash) {
        (1..4).each_with_object({}) { |i, a| a["key#{i}"] = ::FFaker::Lorem.word }
      }
      let(:word_array) { [].fill(0, rand(4..8)) { ::FFaker::Lorem.word } }

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
            expect(arel_value(matches.right)).to eq("%\"arg1\":\"Val 1\"%")
          end
        end

        context "when value is null" do
          it "construct correct WHERE query" do
            matches = described_class.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, nil)
            expect(matches.instance_of?(Arel::Nodes::Matches)).to(eq(true))
            expect(arel_value(matches.right)).to(eq("%\"arg1\":null%"))
          end
        end

        context "when value is a number" do
          it "construct correct WHERE query" do
            grouping = described_class.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, -3.5)
            expect(grouping.instance_of?(Arel::Nodes::Grouping)).to(eq(true))
            disjunction = grouping.expr
            expect(disjunction).to be_an(Arel::Nodes::Or)
            dj_left = disjunction.left
            expect(dj_left).to be_an(Arel::Nodes::Matches)
            expect(arel_value(dj_left.right)).to eq("%\"arg1\":-3.5,%")
            dj_right = disjunction.right
            expect(dj_right).to be_an(Arel::Nodes::Matches)
            expect(arel_value(dj_right.right)).to eq("%\"arg1\":-3.5}%")
          end
        end
      end
    end
  end
end
