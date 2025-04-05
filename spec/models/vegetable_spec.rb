# frozen_string_literal: true

require "spec_helper"
require "support/performance_helpers"

if ENV["DB"] == "postgres" && JsonbVersion.table_exists?
  RSpec.describe Vegetable do
    describe "queries of versions", :versioning do
      let!(:vegetable) { described_class.create(name: "Veggie", mass: 1, color: "green") }

      before do
        vegetable.update(name: "Fidget")
        vegetable.update(name: "Digit")
        described_class.create(name: "Cucumber")
      end

      it "return the vegetable whose name has changed" do
        result = JsonbVersion.where_attribute_changes(:name).map(&:item)
        expect(result).to include(vegetable)
      end

      it "returns the vegetable whose name was Fidget" do
        result = JsonbVersion.where_object_changes_from({ name: "Fidget" }).map(&:item)
        expect(result).to include(vegetable)
      end

      it "returns the vegetable whose name became Digit" do
        result = JsonbVersion.where_object_changes_to({ name: "Digit" }).map(&:item)
        expect(result).to include(vegetable)
      end

      it "returns the vegetable where the object was named Fidget before it changed" do
        result = JsonbVersion.where_object({ name: "Fidget" }).map(&:item)
        expect(result).to include(vegetable)
      end

      it "returns the vegetable that changed to Fidget" do
        result = JsonbVersion.where_object_changes({ name: "Fidget" }).map(&:item)
        expect(result).to include(vegetable)
      end
    end
  end
end
