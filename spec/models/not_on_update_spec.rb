# frozen_string_literal: true

require "spec_helper"

RSpec.describe NotOnUpdate, type: :model do
  let!(:record) { described_class.create!(name: "Name") }

  describe "#save_with_version", versioning: true do
    it "creates a version, regardless" do
      expect { record.paper_trail.save_with_version }.to change {
        PaperTrail::Version.count
      }.by(+1)
    end

    it "captures changes when in_after_callback is true" do
      record.name = "test"
      record.paper_trail.save_with_version(in_after_callback: true)
      changeset = record.versions.last.changeset
      expect(changeset[:name]).to eq(%w[Name test])
    end
  end

  describe "#save_with_version", versioning: false do
    it "returns result of #save if versioning disabled" do
      result = record.paper_trail.save_with_version
      expect(result).to be(true)

      record.name = ""
      result = record.paper_trail.save_with_version
      expect(result).to be(false)
    end
  end
end
