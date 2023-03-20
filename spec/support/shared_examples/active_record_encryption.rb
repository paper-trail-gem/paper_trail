# frozen_string_literal: true

RSpec.shared_examples "active_record_encryption" do |model|
  context "with ActiveRecord encryption", versioning: true do
    ActiveRecord::Encryption.configure(
      primary_key: "test_primary_key",
      deterministic_key: "test_deterministic_key",
      key_derivation_salt: "test_key_derivation_salt"
    )

    let(:record) { model.create name: "James" }

    before { record.update! name: "James Bond" }

    it "does not store plain text values in the database object column" do
      expect(record.versions.last.object_before_type_cast).to include "name"
      expect(record.versions.last.object_before_type_cast).not_to include "James"
    end

    it "does not store plain text values in the database object_changes column" do
      expect(record.versions.last.object_changes_before_type_cast).to include "name"
      expect(record.versions.last.object_changes_before_type_cast).not_to include "James"
    end

    describe "#reify" do
      it "deserializes encrypted values to plaintext" do
        expect(record.versions.last.reify.name).to eq "James"
      end
    end
  end
end
