require "rails_helper"
require Rails.root.join("..", "custom_json_serializer")

describe Boolit, type: :model do
  it { is_expected.to be_versioned }

  it "has a default scope" do
    expect(subject.default_scopes).not_to be_empty
  end

  describe "Versioning", versioning: true do
    subject { Boolit.create! }

    before { subject.update_attributes!(name: FFaker::Name.name) }

    it "has two versions" do
      expect(subject.versions.size).to eq(2)
    end

    it "can be reified and persisted" do
      expect { subject.versions.last.reify.save! }.not_to raise_error
    end

    context "Instance falls out of default scope" do
      before { subject.update_attributes!(scoped: false) }

      it "is NOT scoped" do
        expect(Boolit.first).to be_nil
      end

      it "still can be reified and persisted" do
        expect { subject.paper_trail.previous_version.save! }.not_to raise_error
      end

      context "with `nil` attributes on the live instance" do
        before do
          PaperTrail.serializer = CustomJsonSerializer
          subject.update_attributes!(name: nil)
          subject.update_attributes!(name: FFaker::Name.name)
        end
        after { PaperTrail.serializer = PaperTrail::Serializers::YAML }

        it "does not overwrite that attribute during the reification process" do
          expect(subject.paper_trail.previous_version.name).to be_nil
        end
      end
    end
  end
end
