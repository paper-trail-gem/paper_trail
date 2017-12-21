# frozen_string_literal: true

require "spec_helper"

RSpec.describe LegacyWidget, type: :model, versioning: true do
  describe "#custom_version" do
    it "knows which version it came from" do
      widget = described_class.create(name: "foo", version: 2)
      %w[bar baz].each { |name| widget.update_attributes(name: name) }
      version = widget.versions.last
      reified = version.reify
      expect(reified.custom_version).to(eq(version))
    end
  end

  describe "#previous_version" do
    it "return its previous self" do
      widget = described_class.create(name: "foo", version: 2)
      %w[bar baz].each { |name| widget.update_attributes(name: name) }
      version = widget.versions.last
      reified = version.reify
      expect(reified.paper_trail.previous_version).to(eq(reified.versions[-2].reify))
    end
  end

  describe "#update_attributes" do
    it "does not create a PT version record because the updated column is ignored" do
      described_class.create.update_attributes(version: 1)
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  describe "#version" do
    it "is a normal attribute and has nothing to do with PT" do
      widget = described_class.create(name: "foo", version: 2)
      expect(widget.versions.size).to(eq(1))
      expect(widget.version).to(eq(2))
      widget.update_attributes(version: 3)
      expect(widget.version).to(eq(3))
    end
  end
end
