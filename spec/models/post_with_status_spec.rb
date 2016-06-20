require "rails_helper"

# This model is in the test suite soley for the purpose of testing ActiveRecord::Enum,
# which is available in ActiveRecord4+ only
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
    end
  end
end
