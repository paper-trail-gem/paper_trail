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
      end
    end
  end
end
