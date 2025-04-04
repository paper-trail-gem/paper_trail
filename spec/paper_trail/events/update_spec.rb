# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Events
    ::RSpec.describe Update do
      describe "#data", :versioning do
        context "when is_touch false" do
          it "object_changes is present" do
            carter = Family::CelebrityFamily.create(
              name: "Carter",
              path_to_stardom: "Mexican radio"
            )
            carter.path_to_stardom = "Johnny"
            data = described_class.new(carter, false, false, nil).data
            expect(data[:object_changes]).to eq(
              <<~YAML
                ---
                path_to_stardom:
                - Mexican radio
                - Johnny
              YAML
            )
          end
        end

        context "when is_touch true" do
          it "object_changes is nil" do
            carter = Family::CelebrityFamily.create(
              name: "Carter",
              path_to_stardom: "Mexican radio"
            )
            carter.path_to_stardom = "Johnny"
            data = described_class.new(carter, false, true, nil).data
            expect(data[:object_changes]).to be_nil
          end
        end
      end
    end
  end
end
