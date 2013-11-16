require 'spec_helper'

describe "Articles" do
  let(:valid_params) { { :article => { :title => 'Doh', :content => Faker::Lorem.sentence } } }

  context "versioning disabled" do
    specify { PaperTrail.enabled?.should be_false }

    it "should not create a version" do
      expect { post articles_path(valid_params) }.to_not change(PaperTrail::Version, :count)
    end

    it "should not leak the state of the `PaperTrail.enabled_for_controlller?` into the next test" do
      PaperTrail.enabled_for_controller?.should be_true
    end
  end
end
