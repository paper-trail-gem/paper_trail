require 'spec_helper'

describe Widget do
  describe '`be_versioned` matcher' do
    it { should be_versioned }
  end

  describe "`versioning` option" do
    let(:widget) { Widget.create :name => 'Bob', :an_integer => 1 }

    context :enabled, :versioning => true do
      it 'should enable versioning for models wrapped within a block' do
        widget.versions.size.should == 1
      end
    end

    context '`disabled` (default)' do
      it 'should not enable versioning for models wrapped within a block not marked to used versioning' do
        widget.versions.size.should == 0
      end
    end
  end
end
