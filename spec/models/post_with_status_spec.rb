require "rails_helper"

describe PostWithStatus, type: :model do
  with_versioning do
    let(:post) { described_class.create!(status: "draft") }

    it "saves the enum value in versions" do
      post.published!
      post.archived!
      expect(post.paper_trail.previous_version.published?).to be true
    end

    it "can read enums in version records written by PT 4" do
      post = described_class.create(status: "draft")
      post.published!
      version = post.versions.last
      # Simulate behavior PT 4, which used to save the string version of
      # enums to `object_changes`
      version.update(object_changes: "---\nid:\n- \n- 1\nstatus:\n- draft\n- published\n")
      assert_equal %w(draft published), version.changeset["status"]
    end

    context "storing enum object_changes" do
      subject { post.versions.last }

      it "saves the enum value properly in versions object_changes" do
        post.published!
        post.archived!
        expect(subject.changeset["status"]).to eql %w(published archived)
      end
    end

    describe "#touch_with_version" do
      it "preserves the enum value (and all other attributes)" do
        post = described_class.create(status: :draft)
        expect(post.versions.count).to eq(1)
        expect(post.status).to eq("draft")
        Timecop.travel 1.second.since # because MySQL lacks fractional seconds precision
        post.paper_trail.touch_with_version
        expect(post.versions.count).to eq(2)
        expect(post.versions.last[:object]).to include("status: 0")
        expect(post.paper_trail.previous_version.status).to eq("draft")
      end
    end
  end
end
