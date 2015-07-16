require 'rails_helper'

describe Skipper, :type => :model do
  describe "#update_attributes!", :versioning => true do
    context "updating a skipped attribute" do
      let(:t1) { Time.zone.local(2015, 7, 15, 20, 34, 0) }
      let(:t2) { Time.zone.local(2015, 7, 15, 20, 34, 30) }

      it "should not create a version" do
        skipper = Skipper.create!(:another_timestamp => t1)
        expect {
          skipper.update_attributes!(:another_timestamp => t2)
        }.to_not change { skipper.versions.length }
      end
    end
  end
end
