# frozen_string_literal: true

require "spec_helper"

RSpec.describe Palimpsest, :versioning do
  around do |example|
    original = ActiveRecord::Encryption.config.support_unencrypted_data
    configure_encryption(support_unencrypted_data: support_unencrypted_data)
    example.run
  ensure
    configure_encryption(support_unencrypted_data: original)
  end

  let(:support_unencrypted_data) { true }

  # `title` is only downcased when Active Record serializes it, not when it is
  # assigned, so a record must be re-loaded before the downcased value reaches
  # the version.
  let!(:palimpsest) do
    described_class.create!(
      title: "Treatise On Tides",
      scribe: "Hand A",
      original_scribe: "Unknown"
    )
    described_class.find(described_class.last.id)
  end

  def configure_encryption(support_unencrypted_data:)
    ActiveRecord::Encryption.configure(
      primary_key: "test",
      deterministic_key: "test",
      key_derivation_salt: "test",
      support_unencrypted_data: support_unencrypted_data
    )
  end

  it "reifies the original case, as a record loaded from the database reads" do
    palimpsest.update!(title: "Atlas Of Stars")

    version = palimpsest.versions.last
    expect(version.reify.original_title).to eq("Treatise On Tides")
    expect(version.reify.title).to eq("Treatise On Tides")
  end

  it "leaves an ordinary column named original_* alone" do
    palimpsest.update!(scribe: "Hand B")

    reified = palimpsest.versions.last.reify
    expect(reified.scribe).to eq("Hand A")
    expect(reified.original_scribe).to eq("Unknown")
  end

  it "reifies a record that can still be saved" do
    palimpsest.update!(title: "Atlas Of Stars")

    palimpsest.versions.last.reify.save!

    reloaded = described_class.find(palimpsest.id)
    expect(reloaded.title).to eq("Treatise On Tides")
    expect(reloaded[:title]).to eq("treatise on tides")
  end

  context "when support_unencrypted_data is off" do
    let(:support_unencrypted_data) { false }

    # AR reads the companion column whatever the attribute holds, so the
    # original case survives without `restore_preserved_originals`.
    it "reifies the original case" do
      palimpsest.update!(title: "Atlas Of Stars")

      expect(palimpsest.versions.last.reify.title).to eq("Treatise On Tides")
    end
  end
end
