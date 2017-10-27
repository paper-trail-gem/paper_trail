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
    end
  end

  describe "#changed_notably?", versioning: true do
    context "new record" do
      it "returns true" do
        g = Gadget.new(created_at: Time.now)
        expect(g.paper_trail.changed_notably?).to eq(true)
      end
    end

    context "persisted record without update timestamps" do
      it "only acknowledges non-ignored attrs" do
        gadget = Gadget.create!(created_at: Time.now)
        gadget.name = "Wrench"
        expect(gadget.paper_trail.changed_notably?).to be true
      end

      it "does not acknowledge ignored attr (brand)" do
        gadget = Gadget.create!(created_at: Time.now)
        gadget.brand = "Acme"
        expect(gadget.paper_trail.changed_notably?).to be false
      end
    end

    context "persisted record with update timestamps" do
      it "only acknowledges non-ignored attrs" do
        gadget = Gadget.create!(created_at: Time.now)
        gadget.name = "Wrench"
        gadget.updated_at = Time.now
        expect(gadget.paper_trail.changed_notably?).to be true
      end

      it "does not acknowledge ignored attrs and timestamps only" do
        gadget = Gadget.create!(created_at: Time.now)
        gadget.brand = "Acme"
        gadget.updated_at = Time.now
        expect(gadget.paper_trail.changed_notably?).to be false
      end
    end
  end
end
