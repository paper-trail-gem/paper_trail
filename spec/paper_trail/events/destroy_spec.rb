# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Events
    ::RSpec.describe Destroy do
      describe "#data", skip: true, versioning: true do
        # https://github.com/paper-trail-gem/paper_trail/pull/1108
        it "uses class.name for item_type, not base_class" do
          carter = Family::CelebrityFamily.new(
            name: "Carter",
            path_to_stardom: "Mexican radio"
          )
          data = PaperTrail::Events::Destroy.new(carter, true).data
          expect(data[:item_type]).to eq("Family::CelebrityFamily")
        end
      end
    end
  end
end
