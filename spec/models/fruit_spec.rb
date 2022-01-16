# frozen_string_literal: true

require "spec_helper"

if ENV["DB"] == "postgres" || JsonVersion.table_exists?
  RSpec.describe Fruit, type: :model, versioning: true do
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

    describe "queries of versions" do
      let!(:fruit) { described_class.create(name: "Apple", mass: 1, color: "green") }
      let!(:fruit2) { described_class.create(name: "Pear") }

      before do
        PaperTrail.enabled = true
        fruit.update(name: "Fidget")
        fruit.update(name: "Digit")
      end

      it "return the fruit whose name has changed" do
        expect(JsonVersion.where_attribute_changes(:name).map(&:item)).to include(fruit)
      end

      it "returns the fruit whose name was Fidget" do
        expect(JsonVersion.where_object_changes_from({ name: "Fidget" }).map(&:item)).to include(fruit)
      end

      it "returns the fruit whose name became Digit" do
        expect(JsonVersion.where_object_changes_to({ name: "Digit" }).map(&:item)).to include(fruit)
      end

      it "returns the fruit where the object was named Fidget before it changed" do
        expect(JsonVersion.where_object({ name: "Fidget" }).map(&:item)).to include(fruit)
      end

      it "returns the fruit that changed to Fidget" do
        expect(JsonVersion.where_object_changes({ name: "Fidget" }).map(&:item)).to include(fruit)
      end
    end
  end
end
