# frozen_string_literal: true

require "spec_helper"
require_dependency "on/empty_array"

module On
  RSpec.describe EmptyArray, :versioning do
    describe "#create" do
      it "does not create any version records" do
        record = described_class.create(name: "Alice")
        expect(record.versions.length).to(eq(0))
      end
    end

    describe ".paper_trail.update_columns" do
      it "creates a version record" do
        widget = Widget.create
        expect(widget.versions.length).to eq(1)
        widget.paper_trail.update_columns(name: "Bugle")
        expect(widget.versions.length).to eq(2)
      end
    end

    describe "#update" do
      it "does not create any version records" do
        record = described_class.create(name: "Alice")
        record.update(name: "blah")
        expect(record.versions.length).to(eq(0))
      end
    end
  end
end
