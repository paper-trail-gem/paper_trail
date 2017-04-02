require "rails_helper"

RSpec.describe Skipper, type: :model, versioning: true do
  it { is_expected.to be_versioned }

  describe "#update_attributes!", versioning: true do
    context "updating a skipped attribute" do
      let(:t1) { Time.zone.local(2015, 7, 15, 20, 34, 0) }
      let(:t2) { Time.zone.local(2015, 7, 15, 20, 34, 30) }

      it "does not create a version" do
        skipper = Skipper.create!(another_timestamp: t1)
        expect {
          skipper.update_attributes!(another_timestamp: t2)
        }.not_to(change { skipper.versions.length })
      end
    end
  end

  describe "#reify" do
    let(:t1) { Time.zone.local(2015, 7, 15, 20, 34, 0) }
    let(:t2) { Time.zone.local(2015, 7, 15, 20, 34, 30) }

    context "without preserve (default)" do
      it "has no timestamp" do
        skipper = Skipper.create!(another_timestamp: t1)
        skipper.update_attributes!(another_timestamp: t2, name: "Foobar")
        skipper = skipper.versions.last.reify
        expect(skipper.another_timestamp).to be(nil)
      end
    end

    context "with preserve" do
      it "preserves its timestamp" do
        skipper = Skipper.create!(another_timestamp: t1)
        skipper.update_attributes!(another_timestamp: t2, name: "Foobar")
        skipper = skipper.versions.last.reify(unversioned_attributes: :preserve)
        expect(skipper.another_timestamp).to eq(t2)
      end
    end
  end
end
