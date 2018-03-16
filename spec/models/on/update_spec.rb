# frozen_string_literal: true

require "spec_helper"
require_dependency "on/update"

module On
  RSpec.describe Update, type: :model, versioning: true do
    describe "#versions" do
      it "only creates one version record, for the update event" do
        record = described_class.create(name: "Alice")
        record.update_attributes(name: "blah")
        record.destroy
        expect(record.versions.length).to(eq(1))
        expect(record.versions.last.event).to(eq("update"))
      end
    end

    context "#paper_trail_event" do
      it "rembembers the custom event name" do
        record = described_class.create(name: "Alice")
        record.paper_trail_event = "banana"
        record.update_attributes(name: "blah")
        record.destroy
        expect(record.versions.length).to(eq(1))
        expect(record.versions.last.event).to(eq("banana"))
      end
    end

    describe "#touch" do
      it "does not create a version for the touch event" do
        record = described_class.create(name: "Alice")
        count = record.versions.count
        expect(count).to eq(count)
      end
    end
  end
end
