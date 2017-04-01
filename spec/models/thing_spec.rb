require "rails_helper"

describe Thing, type: :model do
  it { is_expected.to be_versioned }

  describe "does not store object_changes", versioning: true do
    let(:thing) { Thing.create(name: "pencil") }

    it { expect(thing.versions.last.object_changes).to be_nil }
  end
end
