# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gadget do
  let(:gadget) { described_class.create!(name: "Wrench", brand: "Acme") }

  it { is_expected.to be_versioned }

  describe "updates", versioning: true do
    it "generates a version for updates" do
      expect { gadget.update_attribute(:name, "Hammer") }.to(change { gadget.versions.size }.by(1))
    end

    context "when ignored via symbol" do
      it "doesn't generate a version" do
        expect { gadget.update_attribute(:brand, "Picard") }.not_to(change { gadget.versions.size })
      end
    end

    context "when ignored via Hash" do
      it "generates a version when the ignored attribute isn't true" do
        expect { gadget.update_attribute(:color, "Blue") }.to(change { gadget.versions.size }.by(1))
        expect(gadget.versions.last.changeset.keys).to eq %w[color updated_at]
      end

      it "doesn't generate a version when the ignored attribute is true" do
        expect { gadget.update_attribute(:color, "Yellow") }.not_to(change { gadget.versions.size })
      end
    end

    it "still generates a version when only the `updated_at` attribute is updated" do
      # Plus 1 second because MySQL lacks sub-second resolution
      expect {
        gadget.update_attribute(:updated_at, Time.current + 1)
      }.to(change { gadget.versions.size }.by(1))
      expect(
        if YAML.respond_to?(:unsafe_load)
          YAML.unsafe_load(gadget.versions.last.object_changes).keys
        else
          YAML.load(gadget.versions.last.object_changes).keys
        end
      ).to eq(["updated_at"])
    end
  end
end
