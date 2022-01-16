# frozen_string_literal: true

require "spec_helper"
require "support/performance_helpers"

if ENV["DB"] == "postgres" || JsonbVersion.table_exists?
  ::RSpec.describe Vegetable do
    describe "queries of versions" do
      let!(:vegetable) { described_class.create(name: "Veggie", mass: 1, color: "green") }
      let!(:vegetable2) { described_class.create(name: "Cucumber") }

      before do
        PaperTrail.enabled = true
        vegetable.update(name: "Fidget")
        vegetable.update(name: "Digit")
      end

      it "return the vegetable whose name has changed" do
        expect(JsonbVersion.where_attribute_changes(:name).map(&:item)).to include(vegetable)
      end

      it "returns the vegetable whose name was Fidget" do
        expect(JsonbVersion.where_object_changes_from({ name: "Fidget" }).map(&:item)).to include(vegetable)
      end

      it "returns the vegetable whose name became Digit" do
        expect(JsonbVersion.where_object_changes_to({ name: "Digit" }).map(&:item)).to include(vegetable)
      end

      it "returns the vegetable where the object was named Fidget before it changed" do
        expect(JsonbVersion.where_object({ name: "Fidget" }).map(&:item)).to include(vegetable)
      end

      it "returns the vegetable that changed to Fidget" do
        expect(JsonbVersion.where_object_changes({ name: "Fidget" }).map(&:item)).to include(vegetable)
      end
    end
  end
end
