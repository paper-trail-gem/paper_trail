# frozen_string_literal: true

require "spec_helper"

RSpec.describe Thing, type: :model do
  describe "#versions", versioning: true do
    let(:thing) { Thing.create! }

    it "applies the extend option" do
      expect(thing.versions.singleton_class).to be < PrefixVersionsInspectWithCount
      expect(thing.versions.inspect).to start_with("1 versions:")
    end

    it "applies the scope option" do
      expect(Thing.reflect_on_association(:versions).scope).to be_a Proc
      expect(thing.versions.to_sql).to end_with "ORDER BY id desc"
    end
  end
end
