require "rails_helper"

RSpec.describe Document, type: :model do
  describe "`have_a_version_with` matcher", versioning: true do
    it "works with custom versions association" do
      document = Document.create!(name: "Foo")
      document.update_attributes!(name: "Bar")

      expect(document).to have_a_version_with(name: "Foo")
    end
  end

  describe "`have_a_version_with_changes` matcher", versioning: true do
    it "works with custom versions association" do
      document = Document.create!(name: "Foo")
      document.update_attributes!(name: "Bar")

      expect(document).to have_a_version_with_changes(name: "Bar")
    end
  end
end
