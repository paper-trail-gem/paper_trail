# frozen_string_literal: true

require "spec_helper"

if ENV["DB"] == "postgres" || JsonVersion.table_exists?
  RSpec.describe Fruit, type: :model, versioning: true do
    describe "have_a_version_with_changes matcher" do
      it "works with Fruit because Fruit uses JsonVersion" do
        # As of PT 9.0.0, with_version_changes only supports json(b) columns,
        # so that's why were testing the have_a_version_with_changes matcher
        # here.
        banana = Fruit.create!(color: "Red", name: "Banana")
        banana.update!(color: "Yellow")
        expect(banana).to have_a_version_with_changes(color: "Yellow")
        expect(banana).not_to have_a_version_with_changes(color: "Pink")
        expect(banana).not_to have_a_version_with_changes(color: "Yellow", name: "Kiwi")
      end
    end
  end
end
