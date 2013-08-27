require 'spec_helper'

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
