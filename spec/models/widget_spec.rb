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
      describe :whodunnit do
        it { should respond_to(:whodunnit) }

        context "no block given" do
          it "should raise an error" do
            expect { widget.whodunnit('Ben') }.to raise_error(ArgumentError, 'expected to receive a block')
          end
        end

        context "block given" do
          let(:orig_name) { Faker::Name.name }
          let(:new_name) { Faker::Name.name }

          before do
            PaperTrail.whodunnit = orig_name
            widget.versions.last.whodunnit.should == orig_name # persist `widget`
          end

          it "should modify value of `PaperTrail.whodunnit` while executing the block" do
            widget.whodunnit(new_name) do
              PaperTrail.whodunnit.should == new_name
              widget.update_attributes(:name => 'Elizabeth')
            end
            widget.versions.last.whodunnit.should == new_name
          end

          it "should revert the value of `PaperTrail.whodunnit` to it's previous value after executing the block" do
            widget.whodunnit(new_name) { |w| w.update_attributes(:name => 'Elizabeth') }
            PaperTrail.whodunnit.should == orig_name
          end

          context "error within block" do
            it "should ensure that the whodunnit value still reverts to it's previous value" do
              expect { widget.whodunnit(new_name) { raise } }.to raise_error
              PaperTrail.whodunnit.should == orig_name
            end
          end
        end
      end

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
