require 'rails_helper'

describe JoinedVersion, :type => :model, :versioning => true do
  it { expect(JoinedVersion.superclass).to be PaperTrail::Version }

  let(:widget) { Widget.create!(:name => Faker::Name.name) }
  let(:version) { JoinedVersion.first }

  describe "Scopes" do
    describe "default_scope" do
      it { expect(JoinedVersion.default_scopes).not_to be_empty }
    end

    describe "VersionConcern::ClassMethods" do
      before { widget } # persist a widget

      describe '#subsequent' do
        it "shouldn't error out when there is a default_scope that joins" do
          JoinedVersion.subsequent(version).first
        end
      end

      describe '#preceding' do
        it "shouldn't error out when there is a default scope that joins" do
          JoinedVersion.preceding(version).first
        end
      end

      describe '#between' do
        it "shouldn't error out when there is a default scope that joins" do
          JoinedVersion.between(Time.now, 1.minute.from_now).first
        end
      end
    end
  end

  describe "Methods" do
    describe '#index' do
      it { is_expected.to respond_to(:index) }

      it "shouldn't error out when there is a default scope that joins" do
        widget # persist a widget
        version.index
      end
    end
  end
end
