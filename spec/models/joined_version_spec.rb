require 'spec_helper'

describe JoinedVersion, :versioning => true do
  it { JoinedVersion.superclass.should == PaperTrail::Version }

  let(:widget) { Widget.create!(:name => Faker::Name.name) }
  let(:version) { JoinedVersion.first }

  describe "Scopes" do
    describe "default_scope" do
      it { JoinedVersion.default_scopes.should_not be_empty }
    end

    describe "VersionConcern::ClassMethods" do
      before { widget } # persist a widget

      describe :subsequent do
        it "shouldn't error out when there is a default_scope that joins" do
          JoinedVersion.subsequent(version).first
        end
      end

      describe :preceding do
        it "shouldn't error out when there is a default scope that joins" do
          JoinedVersion.preceding(version).first
        end
      end

      describe :between do
        it "shouldn't error out when there is a default scope that joins" do
          JoinedVersion.between(Time.now, 1.minute.from_now).first
        end
      end
    end
  end

  describe "Methods" do
    describe :index do
      it { should respond_to(:index) }

      it "shouldn't error out when there is a default scope that joins" do
        widget # persist a widget
        version.index
      end
    end
  end
end
