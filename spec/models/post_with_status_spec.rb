require "rails_helper"

# This model tests ActiveRecord::Enum, which was added in AR 4.1
# http://edgeguides.rubyonrails.org/4_1_release_notes.html#active-record-enums
describe PostWithStatus, type: :model do
  if defined?(ActiveRecord::Enum)
    with_versioning do
      let(:post) { PostWithStatus.create!(status: "draft") }

      it "should stash the enum value properly in versions" do
        post.published!
        post.archived!
        expect(post.paper_trail.previous_version.published?).to be true
      end

      context "storing enum object_changes" do
        subject { post.versions.last }

        it "should stash the enum value properly in versions object_changes" do
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
end
