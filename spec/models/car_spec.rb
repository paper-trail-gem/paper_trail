require "rails_helper"

RSpec.describe Car, type: :model do
  it { is_expected.to be_versioned }

  describe "changeset", versioning: true do
    it "has the expected keys (see issue 738)" do
      car = Car.create!(name: "Alice")
      car.update_attributes(name: "Bob")
      assert_includes car.versions.last.changeset.keys, "name"
    end
  end
end
