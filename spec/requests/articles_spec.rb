require 'spec_helper'

describe "Articles" do
  let(:valid_params) { { :article => { :title => 'Doh', :content => Faker::Lorem.sentence } } }

  context "versioning disabled" do
    specify { PaperTrail.should_not be_enabled }

    it "should not create a version" do
      PaperTrail.should be_enabled_for_controller
      expect { post articles_path(valid_params) }.to_not change(PaperTrail::Version, :count)
      PaperTrail.should_not be_enabled_for_controller
    end

    it "should not leak the state of the `PaperTrail.enabled_for_controller?` into the next test" do
      PaperTrail.should be_enabled_for_controller
    end
  end
end
