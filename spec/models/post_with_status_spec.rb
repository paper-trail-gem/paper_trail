require 'spec_helper'

# This model is in the test suite soley for the purpose of testing ActiveRecord::Enum,
# which is available in ActiveRecord4+ only
describe PostWithStatus do
  if defined?(ActiveRecord::Enum)
    with_versioning do
      let(:post) { PostWithStatus.create!(:status => 'draft') }

      it "should stash the enum value properly in versions" do
        post.published!
        post.archived!
        post.previous_version.published?.should == true
      end
    end
  end
end
