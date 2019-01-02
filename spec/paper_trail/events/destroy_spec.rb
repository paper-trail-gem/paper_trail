# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Events
    ::RSpec.describe Destroy do
      describe "#data", versioning: true do
        it "includes correct item_subtype" do
          carter = Family::CelebrityFamily.new(
            name: "Carter",
            path_to_stardom: "Mexican radio"
          )
          data = PaperTrail::Events::Destroy.new(carter, true).data
          expect(data[:item_type]).to eq("Family::Family")
          expect(data[:item_subtype]).to eq("Family::CelebrityFamily")
        end

        context "skipper" do
          let(:skipper) { Skipper.create!(another_timestamp: Time.now) }
          let(:data) { PaperTrail::Events::Destroy.new(skipper, false).data }

          it "includes `object` without skipped attributes" do
            object = YAML.load(data[:object])
            expect(object["id"]).to eq(skipper.id)
            expect(object).to have_key("updated_at")
            expect(object).to have_key("created_at")
            expect(object).not_to have_key("another_timestamp")
          end

          it "includes `object_changes` without skipped and ignored attributes" do
            changes = YAML.load(data[:object_changes])
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
