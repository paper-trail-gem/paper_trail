# frozen_string_literal: true

require "spec_helper"

RSpec.describe NotOnUpdate, type: :model do
  describe "#save_with_version", versioning: true do
    let!(:record) { described_class.create! }

    it "creates a version, regardless" do
      expect { record.paper_trail.save_with_version }.to change {
        PaperTrail::Version.count
      }.by(+1)
    end
  end
end
