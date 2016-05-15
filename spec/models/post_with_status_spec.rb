require "rails_helper"

# This model is in the test suite solely for the purpose of testing
# ActiveRecord::Enum, which is available in ActiveRecord4+ only
describe PostWithStatus, type: :model do
  if defined?(ActiveRecord::Enum)
    with_versioning do
      it "should save enum value in versions" do
        post = PostWithStatus.create!(status: "draft") # enum 0
        post.published!
        post.archived!
        expect(post.previous_version.published?).to eq(true)
      end

      describe "#touch_with_version" do
        it "should also save the enum value" do
          post = PostWithStatus.create!(status: "draft") # enum 0
          expect(post.versions.count).to eq(1)
          post.published!
          expect(post.versions.count).to eq(2)
          expect(post.versions[1].object_deserialized["status"]).to eq(0) # draft
          Timecop.travel 1.second.since # because MySQL doesn't do fractional seconds
          post.touch_with_version
          expect(post.versions.count).to eq(3)
          expect(post.versions[2].object_deserialized["status"]).to eq(1) # published
          post.archived!
          expect(post.versions.count).to eq(4)
          expect(post.versions[3].object_deserialized["status"]).to eq(1) # published
          expect(post.previous_version.published?).to eq(true)
        end
      end

      describe ".serialize_attributes_for_paper_trail!" do
        it "preserves enums" do
          expect(
            described_class.serialize_attributes_for_paper_trail!("status" => 1)
          ).to eq("status" => 1)
        end
      end

      context "storing enum object_changes" do
        it "should stash the enum value properly in versions object_changes" do
          post = PostWithStatus.create!(status: "draft") # enum 0
          post.published!
          post.archived!
          expect(post.versions.last.changeset["status"]).to eql %w(published archived)
        end
      end
    end
  end
end
