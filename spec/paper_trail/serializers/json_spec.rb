require "rails_helper"

module PaperTrail
  module Serializers
    RSpec.describe JSON do
      before do
        @hash = {}
        (1..4).each { |i| @hash["key#{i}"] = FFaker::Lorem.word }
        @hash_as_json = @hash.to_json
        @array = []
        (rand(5) + 4).times { (@array << FFaker::Lorem.word) }
        @array_as_json = @array.to_json
      end

      describe ".load" do
        it "deserialize JSON to Ruby" do
          expect(PaperTrail::Serializers::JSON.load(@hash_as_json)).to(eq(@hash))
          expect(PaperTrail::Serializers::JSON.load(@array_as_json)).to(eq(@array))
        end
      end

      describe ".dump" do
        it "serializes Ruby to JSON" do
          expect(PaperTrail::Serializers::JSON.dump(@hash)).to(eq(@hash_as_json))
          expect(PaperTrail::Serializers::JSON.dump(@array)).to(eq(@array_as_json))
        end
      end

      describe ".where_object_condition" do
        context "when value is a string" do
          it "construct correct WHERE query" do
            matches = PaperTrail::Serializers::JSON.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, "Val 1")
            expect(matches.instance_of?(Arel::Nodes::Matches)).to(eq(true))
            expect("%\"arg1\":\"Val 1\"%").to(eq(matches.right.val))
          end
        end

        context "when value is null" do
          it "construct correct WHERE query" do
            matches = PaperTrail::Serializers::JSON.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, nil)
            expect(matches.instance_of?(Arel::Nodes::Matches)).to(eq(true))
            expect("%\"arg1\":null%").to(eq(matches.right.val))
          end
        end

        context "when value is a number" do
          it "construct correct WHERE query" do
            grouping = PaperTrail::Serializers::JSON.
              where_object_condition(PaperTrail::Version.arel_table[:object], :arg1, -3.5)
            expect(grouping.instance_of?(Arel::Nodes::Grouping)).to(eq(true))
            matches = grouping.select { |v| v.instance_of?(Arel::Nodes::Matches) }
            expect("%\"arg1\":-3.5,%").to(eq(matches.first.right.val))
            expect("%\"arg1\":-3.5}%").to(eq(matches.last.right.val))
          end
        end
      end
    end
  end
end
