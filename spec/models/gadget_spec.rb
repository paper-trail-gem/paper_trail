# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gadget, type: :model do
  let(:gadget) { Gadget.create!(name: "Wrench", brand: "Acme") }

  it { is_expected.to be_versioned }

  describe "updates", versioning: true do
    it "generates a version for updates to `name` attribute" do
      expect { gadget.update_attribute(:name, "Hammer") }.to(change { gadget.versions.size }.by(1))
    end

    it "ignores for updates to `brand` attribute" do
      expect { gadget.update_attribute(:brand, "Stanley") }.not_to(change { gadget.versions.size })
    end

    it "still generates a version when only the `updated_at` attribute is updated" do
      # Plus 1 second because MySQL lacks sub-second resolution
      expect {
        gadget.update_attribute(:updated_at, Time.now + 1)
      }.to(change { gadget.versions.size }.by(1))
      expect(
        YAML.safe_load(gadget.versions.last.object_changes, [::Time]).keys
      ).to eq(["updated_at"])
    end
  end
end
