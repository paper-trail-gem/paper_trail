# frozen_string_literal: true

require "spec_helper"

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
          expect(data[:item_type]).to eq("Family::Family")
          expect(data[:item_subtype]).to eq("Family::CelebrityFamily")
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
