# frozen_string_literal: true

RSpec.shared_examples "active_record_encryption" do |model|
  context "when ActiveRecord Encryption is enabled", :versioning do
    let(:record) { model.create(supplier: "ABC", name: "Tomato") }

    before do
      ActiveRecord::Encryption.configure(
        primary_key: "test",
        deterministic_key: "test",
        key_derivation_salt: "test"
      )
    end

    it "is versioned with encrypted values" do
      original_supplier, original_name = record.values_at(:supplier, :name)

      # supplier is encrypted, name is not
      record.update!(supplier: "XYZ", name: "Avocado")

      expect(record.versions.count).to be 2
      expect(record.versions.pluck(:event)).to include("create", "update")

      # versioned encrypted value should be something like
      # "{\"p\":\"zDQU\",\"h\":{\"iv\":\"h2OADmJT3DfK1EZc\",\"at\":\"Urcd0mGSwyu9rGT1vrE5cg==\"}}"

      # check paper trail object
      object = record.versions.last.object
      expect(object.to_s).not_to include("XYZ")
      versioned_supplier, versioned_name = object.values_at("supplier", "name")
      # encrypted column should be versioned with encrypted value
      expect(versioned_supplier).not_to eq(original_supplier)
      # non-encrypted column should be versioned with the original value
      expect(versioned_name).to eq(original_name)
      parsed_versioned_supplier = JSON.parse(versioned_supplier)
      expect(parsed_versioned_supplier)
        .to match(hash_including("p", "h" => hash_including("iv", "at")))

      # check paper trail object_changes
      object_changes = record.versions.last.object_changes
      expect(object_changes.to_s).not_to include("XYZ")
      supplier_changes, name_changes = object_changes.values_at("supplier", "name")
      expect(supplier_changes).not_to eq([original_supplier, "XYZ"])
      expect(name_changes).to eq([original_name, "Avocado"])
      supplier_changes.each do |supplier|
        parsed_supplier = JSON.parse(supplier)
        expect(parsed_supplier).to match(hash_including("p", "h" => hash_including("iv", "at")))
      end
    end

    it "reifies encrypted values to decrypted values" do
      record.update!(supplier: "XYZ", name: "Avocado")
      expect(record.versions.last.reify.supplier).to eq "ABC"
    end
  end
end
