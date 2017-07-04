require "spec_helper"
require_dependency "on/empty_array"

module On
  RSpec.describe EmptyArray, type: :model, versioning: true do
    describe "#create" do
      it "does not create any version records" do
        record = described_class.create(name: "Alice")
        expect(record.versions.length).to(eq(0))
      end
    end

    describe "#touch_with_version" do
      it "creates a version record" do
        record = described_class.create(name: "Alice")
        record.paper_trail.touch_with_version
        expect(record.versions.length).to(eq(1))
        expect(record.versions.first.event).to(eq("update"))
      end
    end

    describe "#update_attributes" do
      it "does not create any version records" do
        record = described_class.create(name: "Alice")
        record.update_attributes(name: "blah")
        expect(record.versions.length).to(eq(0))
      end
    end
  end
end
