require 'rails_helper'

describe NotOnUpdate, :type => :model do
  describe "#touch_with_version", :versioning => true do
    let!(:record) { described_class.create! }

    it "should create a version, regardless" do
      expect { record.touch_with_version }.to change {
        PaperTrail::Version.count
      }.by(+1)
    end

    it "increments the `:updated_at` timestamp" do
      before = record.updated_at
      record.touch_with_version
      expect(record.updated_at).to be > before
    end
  end
end
