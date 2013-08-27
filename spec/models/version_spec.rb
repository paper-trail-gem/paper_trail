require 'spec_helper'

describe PaperTrail::Version do
  context 'default' do
    it 'should have versioning off by default' do
      ::PaperTrail.enabled?.should_not be_true
    end
    it 'should turn versioning on in a with_versioning block' do
      ::PaperTrail.enabled?.should be_false
      with_versioning do
        ::PaperTrail.enabled?.should be_true
      end
      ::PaperTrail.enabled?.should be_false
    end
  end

  context 'versioning: true', versioning: true do
    it 'should have versioning on by default' do
      ::PaperTrail.enabled?.should be_true
    end
    it 'should keep versioning on after a with_versioning block' do
      ::PaperTrail.enabled?.should be_true
      with_versioning do
        ::PaperTrail.enabled?.should be_true
      end
      ::PaperTrail.enabled?.should be_true
    end
  end
end

describe Widget do
  it { should be_versioned }

  context 'be_versioned matcher', versioning: true do
    it 'should respond to be_versioned' do
      widget = Widget.create name: 'Bob', an_integer: 1
      widget.should be_versioned
      widget.versions.size.should == 1
    end
  end
end
