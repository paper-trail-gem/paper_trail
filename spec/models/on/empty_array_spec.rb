# frozen_string_literal: true

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
        v = record.versions.first
        expect(v.event).to(eq("update"))
        expect(v.object_deserialized.fetch("name")).to eq("Alice")
      end
    end

    describe ".paper_trail.update_columns" do
      it "creates a version record" do
        widget = Widget.create
        assert_equal 1, widget.versions.length
        widget.paper_trail.update_columns(name: "Bugle")
        assert_equal 2, widget.versions.length
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
