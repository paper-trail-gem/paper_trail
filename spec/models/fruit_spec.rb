# frozen_string_literal: true

require "spec_helper"

if ENV["DB"] == "postgres" && JsonVersion.table_exists?
  RSpec.describe Fruit, versioning: true do
    describe "have_a_version_with_changes matcher" do
      it "works with Fruit because Fruit uses JsonVersion" do
        # As of PT 9.0.0, with_version_changes only supports json(b) columns,
        # so that's why were testing the have_a_version_with_changes matcher
        # here.
        banana = described_class.create!(color: "Red", name: "Banana")
        banana.update!(color: "Yellow")
        expect(banana).to have_a_version_with_changes(color: "Yellow")
        expect(banana).not_to have_a_version_with_changes(color: "Pink")
        expect(banana).not_to have_a_version_with_changes(color: "Yellow", name: "Kiwi")
      end
    end

    describe "queries of versions", versioning: true do
      let!(:fruit) { described_class.create(name: "Apple", mass: 1, color: "green") }

      before do
        described_class.create(name: "Pear")
        fruit.update(name: "Fidget")
        fruit.update(name: "Digit")
      end

      it "return the fruit whose name has changed" do
        result = JsonVersion.where_attribute_changes(:name).map(&:item)
        expect(result).to include(fruit)
      end

      it "returns the fruit whose name was Fidget" do
        result = JsonVersion.where_object_changes_from({ name: "Fidget" }).map(&:item)
        expect(result).to include(fruit)
      end

      it "returns the fruit whose name became Digit" do
        result = JsonVersion.where_object_changes_to({ name: "Digit" }).map(&:item)
        expect(result).to include(fruit)
      end

      it "returns the fruit where the object was named Fidget before it changed" do
        result = JsonVersion.where_object({ name: "Fidget" }).map(&:item)
        expect(result).to include(fruit)
      end

      it "returns the fruit that changed to Fidget" do
        result = JsonVersion.where_object_changes({ name: "Fidget" }).map(&:item)
        expect(result).to include(fruit)
      end
    end
  end
end
