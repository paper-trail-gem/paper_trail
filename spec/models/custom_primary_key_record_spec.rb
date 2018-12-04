# frozen_string_literal: true

require "spec_helper"

RSpec.describe CustomPrimaryKeyRecord, type: :model do
  it { is_expected.to be_versioned }

  describe "#versions" do
    it "returns instances of CustomPrimaryKeyRecordVersion", versioning: true do
      custom_primary_key_record = described_class.create!
      custom_primary_key_record.update!(name: "bob")
      version = custom_primary_key_record.versions.last
      expect(version).to be_a(CustomPrimaryKeyRecordVersion)
      version_from_db = CustomPrimaryKeyRecordVersion.last
      expect(version_from_db.reify).to be_a(CustomPrimaryKeyRecord)
      custom_primary_key_record.destroy
      expect(CustomPrimaryKeyRecordVersion.last.reify).to be_a(CustomPrimaryKeyRecord)
    end
  end
end
