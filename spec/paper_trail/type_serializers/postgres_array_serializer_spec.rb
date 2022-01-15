# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module TypeSerializers
    ::RSpec.describe PostgresArraySerializer do
      let(:word_array) { [].fill(0, rand(4..8)) { ::FFaker::Lorem.word } }
      let(:word_array_as_string) { word_array.join("|") }

      let(:the_thing) { described_class.new("foo", "bar") }

      describe ".deserialize" do
        it "deserializes array to Ruby" do
          expect(the_thing.deserialize(word_array)).to eq(word_array)
        end

        it "deserializes string to Ruby array" do
          expect(the_thing).to have_received(:deserialize_with_ar).and_return(word_array)
          expect(the_thing.deserialize(word_array_as_string)).to eq(word_array)
        end
      end

      describe ".dump" do
        it "serializes Ruby to JSON" do
          expect(the_thing.serialize(word_array)).to eq(word_array)
        end
      end

    end
  end
end
