# frozen_string_literal: true

require "spec_helper"

# Regression fixture for overridden polymorphic type names.
module PolymorphicNameOverride
  class Widget < ApplicationRecord
    self.table_name = "widgets"
    has_paper_trail

    def self.polymorphic_name
      "Widget"
    end
  end
end

module PaperTrail
  module Events
    ::RSpec.describe Destroy do
      describe "#data", :versioning do
        it "includes correct item_subtype" do
          carter = Family::CelebrityFamily.new(
            name: "Carter",
            path_to_stardom: "Mexican radio"
          )
          data = described_class.new(carter, true).data
          version = PaperTrail::Version.new(data)
          expect(data[:item]).to eq(carter)
          expect(version.item_type).to eq("Family::Family")
          expect(data[:item_subtype]).to eq("Family::CelebrityFamily")
        end

        # Destroy versions should respect `polymorphic_name` just like create/update.
        it "uses polymorphic_name for destroy versions" do
          widget = PolymorphicNameOverride::Widget.create!(name: "Henry")
          widget.update!(name: "Harry")
          widget.destroy

          expect(widget.versions.pluck(:event)).to eq(%w[create update destroy])
          expect(widget.versions.pluck(:item_type).uniq).to eq(["Widget"])
        end

        context "with skipper" do
          let(:skipper) { Skipper.create!(another_timestamp: Time.current) }
          let(:data) { described_class.new(skipper, false).data }

          it "includes `object` without skipped attributes" do
            object = if ::YAML.respond_to?(:unsafe_load)
                       YAML.unsafe_load(data[:object])
                     else
                       YAML.load(data[:object])
                     end
            expect(object["id"]).to eq(skipper.id)
            expect(object).to have_key("updated_at")
            expect(object).to have_key("created_at")
            expect(object).not_to have_key("another_timestamp")
          end

          it "includes `object_changes` without skipped and ignored attributes" do
            changes = if ::YAML.respond_to?(:unsafe_load)
                        YAML.unsafe_load(data[:object_changes])
                      else
                        YAML.load(data[:object_changes])
                      end
            expect(changes["id"]).to eq([skipper.id, nil])
            expect(changes["updated_at"][0]).to be_present
            expect(changes["updated_at"][1]).to be_nil
            expect(changes).not_to have_key("created_at")
            expect(changes).not_to have_key("another_timestamp")
          end
        end
      end
    end
  end
end
