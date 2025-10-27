# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module AttributeSerializers
    ::RSpec.describe ObjectAttribute do
      if ENV["DB"] == "postgres"
        describe "postgres-specific column types" do
          describe "#serialize" do
            it "serializes a postgres array into a ruby array" do
              attrs = { "post_ids" => [1, 2, 3] }
              described_class.new(PostgresUser).serialize(attrs)
              expect(attrs["post_ids"]).to eq [1, 2, 3]
            end

            it "serializes a postgres range into a ruby array" do
              attrs = { "range" => 1..5 }
              described_class.new(PostgresUser).serialize(attrs)
              expect(attrs["range"]).to eq 1..5
            end
          end

          describe "#deserialize" do
            it "deserializes a ruby array correctly" do
              attrs = { "post_ids" => [1, 2, 3] }
              described_class.new(PostgresUser).deserialize(attrs)
              expect(attrs["post_ids"]).to eq [1, 2, 3]
            end

            it "deserializes an array serialized with Rails <= 5.0.1 correctly" do
              attrs = { "post_ids" => "{1,2,3}" }
              described_class.new(PostgresUser).deserialize(attrs)
              expect(attrs["post_ids"]).to eq [1, 2, 3]
            end

            it "deserializes an array of time objects correctly" do
              date1 = 1.day.ago
              date2 = 2.days.ago
              date3 = 3.days.ago
              attrs = { "post_ids" => [date1, date2, date3] }
              described_class.new(PostgresUser).serialize(attrs)
              described_class.new(PostgresUser).deserialize(attrs)
              expect(attrs["post_ids"]).to eq [date1, date2, date3]
            end

            it "deserializes a ruby range correctly" do
              attrs = { "range" => 1..5 }
              described_class.new(PostgresUser).deserialize(attrs)
              expect(attrs["range"]).to eq 1..5
            end
          end
        end
      end
    end
  end
end
