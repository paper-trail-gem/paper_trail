# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module TypeSerializers
    ::RSpec.describe PostgresRangeSerializer do
      if ENV["DB"] == "postgres"
        let(:active_record_serializer) {
          ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Range.new(subtype)
        }
        let(:serializer) { described_class.new(active_record_serializer) }

        describe ".deserialize" do
          let(:range_string) { range_ruby.to_s }

          context "with daterange" do
            let(:subtype) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Date.new }
            let(:range_ruby) { Date.new(2024, 1, 1)..Date.new(2024, 1, 31) }

            it "deserializes to Ruby" do
              expect(serializer.deserialize(range_string)).to eq(range_ruby)
            end

            context "with exclude_end" do
              let(:range_ruby) { Date.new(2024, 1, 1)...Date.new(2024, 1, 31) }

              it "deserializes to Ruby" do
                expect(serializer.deserialize(range_string)).to eq(range_ruby)
              end
            end
          end

          context "with numrange" do
            let(:subtype) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal.new }
            let(:range_ruby) { 1.5..3.5 }

            it "deserializes to Ruby" do
              expect(serializer.deserialize(range_string)).to eq(range_ruby)
            end
          end

          context "with tsrange" do
            let(:subtype) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Timestamp.new }
            let(:range_ruby) { 1.day.ago..1.day.from_now }

            it "deserializes to Ruby" do
              expect(serializer.deserialize(range_string)).to eq(range_ruby)
            end
          end

          context "with tstzrange" do
            let(:subtype) {
              ActiveRecord::ConnectionAdapters::PostgreSQL::OID::TimestampWithTimeZone.new
            }
            let(:range_ruby) { Date.new(2021, 1, 1)..Date.new(2021, 1, 31) }

            it "deserializes to Ruby" do
              expect(serializer.deserialize(range_string)).to eq(range_ruby)
            end
          end

          context "with int4range" do
            let(:subtype) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer.new }
            let(:range_ruby) { 1..10 }

            it "deserializes to Ruby" do
              expect(serializer.deserialize(range_string)).to eq(range_ruby)
            end
          end

          context "with int8range" do
            let(:subtype) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer.new }
            let(:range_ruby) { 2_200_000_000..2_500_000_000 }

            it "deserializes to Ruby" do
              expect(serializer.deserialize(range_string)).to eq(range_ruby)
            end
          end
        end
      end
    end
  end
end
