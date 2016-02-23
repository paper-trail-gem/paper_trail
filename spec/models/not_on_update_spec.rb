require "rails_helper"

describe NotOnUpdate, type: :model do
  describe "#touch_with_version", versioning: true do
    let!(:record) { described_class.create! }

    it "should create a version, regardless" do
      expect { record.paper_trail.touch_with_version }.to change {
        PaperTrail::Version.count
      }.by(+1)
    end

    it "increments the `:updated_at` timestamp" do
      before = record.updated_at
      # Travel 1 second because MySQL lacks sub-second resolution
      Timecop.travel(1) do
        record.paper_trail.touch_with_version
      end
      expect(record.updated_at).to be > before
    end
  end
end
