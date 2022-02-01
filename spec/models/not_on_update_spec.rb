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

    it "captures changes when in_after_callback is true" do
      record.name = "test"
      record.paper_trail.save_with_version(in_after_callback: true)
      as_stored_in_version = HashWithIndifferentAccess[
        YAML.load(record.versions.last.object_changes)
      ]
      expect(as_stored_in_version[:name].last).to(eq("test"))
    end
  end
end
