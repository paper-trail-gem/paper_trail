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

  describe "#touch_with_version", versioning: true do
    let!(:record) { described_class.create! }

    it "creates a version, regardless" do
      allow(::ActiveSupport::Deprecation).to receive(:warn)
      expect { record.paper_trail.touch_with_version }.to change {
        PaperTrail::Version.count
      }.by(+1)
      expect(::ActiveSupport::Deprecation).to have_received(:warn).once
    end

    it "increments the `:updated_at` timestamp" do
      before = record.updated_at
      allow(::ActiveSupport::Deprecation).to receive(:warn)
      record.paper_trail.touch_with_version
      expect(::ActiveSupport::Deprecation).to have_received(:warn).once
      expect(record.updated_at).to be > before
    end
  end
end
