require "rails_helper"

describe Widget, type: :model do
  describe "`be_versioned` matcher" do
    it { is_expected.to be_versioned }
  end

  let(:widget) { Widget.create! name: "Bob", an_integer: 1 }

  describe "`have_a_version_with` matcher", versioning: true do
    before do
      widget.update_attributes!(name: "Leonard", an_integer: 1)
      widget.update_attributes!(name: "Tom")
      widget.update_attributes!(name: "Bob")
    end

    it "is possible to do assertions on versions" do
      expect(widget).to have_a_version_with name: "Leonard", an_integer: 1
      expect(widget).to have_a_version_with an_integer: 1
      expect(widget).to have_a_version_with name: "Tom"
    end
  end

  describe "versioning option" do
    context "enabled", versioning: true do
      it "should enable versioning" do
        expect(widget.versions.size).to eq(1)
      end
    end

    context "disabled (default)" do
      it "should not enable versioning" do
        expect(widget.versions.size).to eq(0)
      end
    end
  end

  describe "Callbacks", versioning: true do
    describe :before_save do
      context ":on => :update" do
        before { widget.update_attributes!(name: "Foobar") }

        subject { widget.versions.last.reify }

        it "resets value for timestamp attrs for update so that value gets updated properly" do
          # Travel 1 second because MySQL lacks sub-second resolution
          Timecop.travel(1) do
            expect { subject.save! }.to change(subject, :updated_at)
          end
        end
      end
    end

    describe :after_create do
      let(:widget) { Widget.create!(name: "Foobar", created_at: Time.now - 1.week) }

      it "corresponding version should use the widget's `updated_at`" do
        expect(widget.versions.last.created_at.to_i).to eq(widget.updated_at.to_i)
      end
    end

    describe :after_update do
      before { widget.update_attributes!(name: "Foobar", updated_at: Time.now + 1.week) }

      subject { widget.versions.last.reify }

      it { expect(subject.paper_trail).not_to be_live }

      it "should clear the `versions_association_name` virtual attribute" do
        subject.save!
        expect(subject.paper_trail).to be_live
      end

      it "corresponding version should use the widget updated_at" do
        expect(widget.versions.last.created_at.to_i).to eq(widget.updated_at.to_i)
      end
    end

    describe :after_destroy do
      it "should create a version for that event" do
        expect { widget.destroy }.to change(widget.versions, :count).by(1)
      end

      it "should assign the version into the `versions_association_name`" do
        expect(widget.version).to be_nil
        widget.destroy
        expect(widget.version).not_to be_nil
        expect(widget.version).to eq(widget.versions.last)
      end
    end

    describe :after_rollback do
      let(:rolled_back_name) { "Big Moo" }

      before do
        begin
          widget.transaction do
            widget.update_attributes!(name: rolled_back_name)
            widget.update_attributes!(name: Widget::EXCLUDED_NAME)
          end
        rescue ActiveRecord::RecordInvalid
          widget.reload
          widget.name = nil
          widget.save
        end
      end

      it "does not create an event for changes that did not happen" do
        widget.versions.map(&:changeset).each do |changeset|
          expect(changeset.fetch("name", [])).to_not include(rolled_back_name)
        end
      end

      it "has not yet loaded the assocation" do
        expect(widget.versions).to_not be_loaded
      end
    end
  end

  describe "Association", versioning: true do
    describe "sort order" do
      it "should sort by the timestamp order from the `VersionConcern`" do
        expect(widget.versions.to_sql).to eq(
          widget.versions.reorder(PaperTrail::Version.timestamp_sort_order).to_sql
        )
      end
    end
  end

  if defined?(ActiveRecord::IdentityMap) && ActiveRecord::IdentityMap.respond_to?(:without)
    describe "IdentityMap", versioning: true do
      it "should not clobber the IdentityMap when reifying" do
        widget.update_attributes name: "Henry", created_at: Time.now - 1.day
        widget.update_attributes name: "Harry"
        expect(ActiveRecord::IdentityMap).to receive(:without).once
        widget.versions.last.reify
      end
    end
  end

  describe "Methods" do
    describe "Instance", versioning: true do
      describe '#paper_trail.originator' do
        describe "return value" do
          let(:orig_name) { FFaker::Name.name }
          let(:new_name) { FFaker::Name.name }
          before { PaperTrail.whodunnit = orig_name }

          context "accessed from live model instance" do
            specify { expect(widget.paper_trail).to be_live }

            it "should return the originator for the model at a given state" do
              expect(widget.paper_trail.originator).to eq(orig_name)
              widget.paper_trail.whodunnit(new_name) { |w|
                w.update_attributes(name: "Elizabeth")
              }
              expect(widget.paper_trail.originator).to eq(new_name)
            end
          end

          context "accessed from a reified model instance" do
            before do
              widget.update_attributes(name: "Andy")
              PaperTrail.whodunnit = new_name
              widget.update_attributes(name: "Elizabeth")
            end

            context "default behavior (no `options[:dup]` option passed in)" do
              let(:reified_widget) { widget.versions[1].reify }

              it "should return the appropriate originator" do
                expect(reified_widget.paper_trail.originator).to eq(orig_name)
              end

              it "should not create a new model instance" do
                expect(reified_widget).not_to be_new_record
              end
            end

            context "creating a new instance (`options[:dup] == true`)" do
              let(:reified_widget) { widget.versions[1].reify(dup: true) }

              it "should return the appropriate originator" do
                expect(reified_widget.paper_trail.originator).to eq(orig_name)
              end

              it "should not create a new model instance" do
                expect(reified_widget).to be_new_record
              end
            end
          end
        end
      end

      describe '#version_at' do
        context "Timestamp argument is AFTER object has been destroyed" do
          it "should return `nil`" do
            widget.update_attribute(:name, "foobar")
            widget.destroy
            expect(widget.paper_trail.version_at(Time.now)).to be_nil
          end
        end
      end

      describe '#whodunnit' do
        it { is_expected.to respond_to(:whodunnit) }

        context "no block given" do
          it "should raise an error" do
            expect {
              widget.paper_trail.whodunnit("Ben")
            }.to raise_error(ArgumentError, "expected to receive a block")
          end
        end

        context "block given" do
          let(:orig_name) { FFaker::Name.name }
          let(:new_name) { FFaker::Name.name }

          before do
            PaperTrail.whodunnit = orig_name
            expect(widget.versions.last.whodunnit).to eq(orig_name) # persist `widget`
          end

          it "should modify value of `PaperTrail.whodunnit` while executing the block" do
            widget.paper_trail.whodunnit(new_name) do
              expect(PaperTrail.whodunnit).to eq(new_name)
              widget.update_attributes(name: "Elizabeth")
            end
            expect(widget.versions.last.whodunnit).to eq(new_name)
          end

          context "after executing the block" do
            it "reverts value of whodunnit to previous value" do
              widget.paper_trail.whodunnit(new_name) { |w|
                w.update_attributes(name: "Elizabeth")
              }
              expect(PaperTrail.whodunnit).to eq(orig_name)
            end
          end

          context "error within block" do
            it "still reverts the whodunnit value to previous value" do
              expect {
                widget.paper_trail.whodunnit(new_name) { raise }
              }.to raise_error(RuntimeError)
              expect(PaperTrail.whodunnit).to eq(orig_name)
            end
          end
        end
      end

      describe '#touch_with_version' do
        it "creates a version" do
          count = widget.versions.size
          # Travel 1 second because MySQL lacks sub-second resolution
          Timecop.travel(1) do
            widget.paper_trail.touch_with_version
          end
          expect(widget.versions.size).to eq(count + 1)
        end

        it "increments the `:updated_at` timestamp" do
          time_was = widget.updated_at
          # Travel 1 second because MySQL lacks sub-second resolution
          Timecop.travel(1) do
            widget.paper_trail.touch_with_version
          end
          expect(widget.updated_at).to be > time_was
        end
      end
    end

    describe "Class" do
      describe ".paper_trail.enabled?" do
        it "returns true" do
          expect(Widget.paper_trail.enabled?).to eq(true)
        end
      end

      describe ".disable" do
        it "should set the `paper_trail.enabled?` to `false`" do
          expect(Widget.paper_trail.enabled?).to eq(true)
          Widget.paper_trail.disable
          expect(Widget.paper_trail.enabled?).to eq(false)
        end
      end

      describe ".enable" do
        it "should set the `paper_trail.enabled?` to `true`" do
          Widget.paper_trail.disable
          expect(Widget.paper_trail.enabled?).to eq(false)
          Widget.paper_trail.enable
          expect(Widget.paper_trail.enabled?).to eq(true)
        end
      end
    end
  end
end
