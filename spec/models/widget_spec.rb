require 'spec_helper'

describe Widget do
  describe '`be_versioned` matcher' do
    it { should be_versioned }
  end

  let(:widget) { Widget.create :name => 'Bob', :an_integer => 1 }

  describe "`versioning` option" do
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

  describe "Methods" do
    describe "Instance", :versioning => true do
      describe :touch_with_version do
        it { should respond_to(:touch_with_version) }

        it "should generate a version" do
          count = widget.versions.size
          widget.touch_with_version
          widget.versions.size.should == count + 1
        end

        it "should increment the `:updated_at` timestamp" do
          time_was = widget.updated_at
          widget.touch_with_version
          widget.updated_at.should > time_was
        end
      end
    end

    describe "Class" do
      subject { Widget }

      describe :paper_trail_off! do
        it { should respond_to(:paper_trail_off!) }

        it 'should set the `paper_trail_enabled_for_model?` to `false`' do
          subject.paper_trail_enabled_for_model?.should be_true
          subject.paper_trail_off!
          subject.paper_trail_enabled_for_model?.should be_false
        end
      end

      describe :paper_trail_off do
        it { should respond_to(:paper_trail_off) }

        it 'should set the invoke `paper_trail_off!`' do
          subject.should_receive(:warn)
          subject.should_receive(:paper_trail_off!)
          subject.paper_trail_off
        end

        it 'should display a deprecation warning' do
          subject.should_receive(:warn).with("DEPRECATED: use `paper_trail_on!` instead of `paper_trail_on`. Support for `paper_trail_on` will be removed in PaperTrail 3.1")
          subject.paper_trail_on
        end
      end

      describe :paper_trail_on! do
        before { subject.paper_trail_off! }

        it { should respond_to(:paper_trail_on!) }

        it 'should set the `paper_trail_enabled_for_model?` to `true`' do
          subject.paper_trail_enabled_for_model?.should be_false
          subject.paper_trail_on!
          subject.paper_trail_enabled_for_model?.should be_true
        end
      end

      describe :paper_trail_on do
        before { subject.paper_trail_off! }

        it { should respond_to(:paper_trail_on) }

        it 'should set the invoke `paper_trail_on!`' do
          subject.should_receive(:warn)
          subject.should_receive(:paper_trail_on!)
          subject.paper_trail_on
        end

        it 'should display a deprecation warning' do
          subject.should_receive(:warn).with("DEPRECATED: use `paper_trail_on!` instead of `paper_trail_on`. Support for `paper_trail_on` will be removed in PaperTrail 3.1")
          subject.paper_trail_on
        end
      end
    end
  end
end
