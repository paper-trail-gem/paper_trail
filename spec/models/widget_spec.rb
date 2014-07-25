require 'spec_helper'

describe Widget do
  describe '`be_versioned` matcher' do
    it { should be_versioned }
  end

  let(:widget) { Widget.create! :name => 'Bob', :an_integer => 1 }

  describe '`have_a_version_with` matcher', :versioning => true do
    before do
      widget.update_attributes!(:name => 'Leonard', :an_integer => 1 )
      widget.update_attributes!(:name => 'Tom')
      widget.update_attributes!(:name => 'Bob')
    end

    it "is possible to do assertions on versions" do
       widget.should have_a_version_with :name => 'Leonard', :an_integer => 1
       widget.should have_a_version_with :an_integer => 1
       widget.should have_a_version_with :name => 'Tom'
    end
  end

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

  describe "Callbacks", :versioning => true do
    describe :before_save do
      context ':on => :update' do
        before { widget.update_attributes!(:name => 'Foobar') }

        subject { widget.versions.last.reify }

        it "should reset the value for the timestamp attrs for update so that value gets updated properly" do
          expect { subject.save! }.to change(subject, :updated_at)
        end
      end
    end

    describe :after_update do
      before { widget.update_attributes!(:name => 'Foobar') }

      subject { widget.versions.last.reify }

      it { subject.should_not be_live }

      it "should clear the `versions_association_name` virtual attribute" do
        subject.save!
        subject.should be_live
      end
    end

    describe :after_destroy do
      it "should create a version for that event" do
        expect { widget.destroy }.to change(widget.versions, :count).by(1)
      end

      it "should assign the version into the `versions_association_name`" do
        widget.version.should be_nil
        widget.destroy
        widget.version.should_not be_nil
        widget.version.should == widget.versions.last
      end
    end
  end

  describe "Association", :versioning => true do
    describe "sort order" do
      it "should sort by the timestamp order from the `VersionConcern`" do
        widget.versions.to_sql.should ==
          widget.versions.reorder(PaperTrail::Version.timestamp_sort_order).to_sql
      end
    end
  end

  describe "Methods" do
    describe "Instance", :versioning => true do
      describe :originator do
        it { should respond_to(:originator) }

        describe "return value" do
          let(:orig_name) { Faker::Name.name }
          let(:new_name) { Faker::Name.name }
          before { PaperTrail.whodunnit = orig_name }

          context "accessed from live model instance" do
            specify { widget.should be_live }

            it "should return the originator for the model at a given state" do
              widget.originator.should == orig_name
              widget.whodunnit(new_name) { |w| w.update_attributes(:name => 'Elizabeth') }
              widget.originator.should == new_name
            end
          end

          context "accessed from a reified model instance" do
            before do
              widget.update_attributes(:name => 'Andy')
              PaperTrail.whodunnit = new_name
              widget.update_attributes(:name => 'Elizabeth')
            end

            context "reverting a change" do
              let(:reified_widget) { widget.versions[1].reify }

              it "should return the appropriate originator" do
                reified_widget.originator.should == orig_name
              end

              it "should not create a new model instance" do
                reified_widget.should_not be_new_record
              end
            end

            context "creating a new instance" do
              let(:reified_widget) { widget.versions[1].reify(dup: true) }

              it "should return the appropriate originator" do
                reified_widget.originator.should == orig_name
              end

              it "should not create a new model instance" do
                reified_widget.should be_new_record
              end
            end
          end
        end
      end

      describe :version_at do
        it { should respond_to(:version_at) }

        context "Timestamp argument is AFTER object has been destroyed" do
          before do
            widget.update_attribute(:name, 'foobar')
            widget.destroy
          end

          it "should return `nil`" do
            widget.version_at(Time.now).should be_nil
          end
        end
      end

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
          subject.paper_trail_enabled_for_model?.should == true
          subject.paper_trail_off!
          subject.paper_trail_enabled_for_model?.should == false
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
          subject.paper_trail_enabled_for_model?.should == false
          subject.paper_trail_on!
          subject.paper_trail_enabled_for_model?.should == true
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
