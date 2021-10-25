# frozen_string_literal: true

require "spec_helper"
require "support/performance_helpers"

RSpec.describe(FooWidget, versioning: true) do
  context "with a subclass" do
    let(:foo) { described_class.create }

    before do
      foo.update!(name: "Foo")
    end

    it "reify with the correct type" do
      expect(PaperTrail::Version.last.previous).to(eq(foo.versions.first))
      expect(PaperTrail::Version.last.next).to(be_nil)
    end

    it "returns the correct originator" do
      PaperTrail.request.whodunnit = "Ben"
      foo.update_attribute(:name, "Geoffrey")
      expect(foo.paper_trail.originator).to(eq(PaperTrail.request.whodunnit))
    end

    context "when destroyed" do
      before { foo.destroy }

      it "reify with the correct type" do
        assert_kind_of(described_class, foo.versions.last.reify)
        expect(PaperTrail::Version.last.previous).to(eq(foo.versions[1]))
        expect(PaperTrail::Version.last.next).to(be_nil)
      end
    end
  end
end
