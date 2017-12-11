# frozen_string_literal: true

require "spec_helper"
require_dependency "on/create"

module On
  RSpec.describe Create, type: :model, versioning: true do
    describe "#versions" do
      it "only have a version for the create event" do
        record = described_class.create(name: "Alice")
        record.update_attributes(name: "blah")
        record.destroy
        expect(record.versions.length).to(eq(1))
        expect(record.versions.last.event).to(eq("create"))
      end
    end

    context "#paper_trail_event" do
      it "rembembers the custom event name" do
        record = described_class.new
        record.paper_trail_event = "banana"
        record.update_attributes(name: "blah")
        record.destroy
        expect(record.versions.length).to(eq(1))
        expect(record.versions.last.event).to(eq("banana"))
      end
    end
  end
end
