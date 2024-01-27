# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module AttributeSerializers
    ::RSpec.describe ObjectAttribute do
      if ENV["DB"] == "postgres"
        describe "postgres-specific column types" do
          describe "#serialize" do
            it "serializes a postgres array into a plain array" do
              attrs = { "post_ids" => [1, 2, 3] }
              described_class.new(PostgresUser).serialize(attrs)
              expect(attrs["post_ids"]).to eq [1, 2, 3]
            end
          end

          describe "#deserialize" do
            it "deserializes a plain array correctly" do
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
          end
        end
      end

      describe "#serialize" do
        it "serializes a time object into a plain string" do
          time = Time.zone.local(2015, 7, 15, 20, 34, 0)
          attrs = { "created_at" => time }
          described_class.new(Widget).serialize(attrs)

          if ENV["DB"] == "postgres" || ENV["DB"] == "sqlite"
            expect(attrs["created_at"]).not_to be_a(ActiveSupport::TimeWithZone)
            expect(attrs["created_at"]).to be_a(String)
            expect(attrs["created_at"]).to match(/2015/)
          else
            expect(attrs["created_at"].to_i).to eq(time.to_i)
          end
        end
      end

      describe "#deserialize" do
        it "deserializes a time object correctly" do
          time = 1.day.ago
          attrs = { "created_at" => time }
          described_class.new(Widget).serialize(attrs)
          described_class.new(Widget).deserialize(attrs)
          expect(attrs["created_at"].to_i).to eq(time.to_i)
        end
      end
    end
  end
end
