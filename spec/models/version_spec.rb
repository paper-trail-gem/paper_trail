require 'spec_helper'

describe PaperTrail::Version do
  it "should include the `VersionConcern` module to get base functionality" do
    PaperTrail::Version.should include(PaperTrail::VersionConcern)
  end

  describe "Attributes" do
    it { should have_db_column(:item_type).of_type(:string) }
    it { should have_db_column(:item_id).of_type(:integer) }
    it { should have_db_column(:event).of_type(:string) }
    it { should have_db_column(:whodunnit).of_type(:string) }
    it { should have_db_column(:object).of_type(:text) }
    it { should have_db_column(:created_at).of_type(:datetime) }
  end

  describe "Indexes" do
    it { should have_db_index([:item_type, :item_id]) }
  end

  describe "Methods" do
    describe "Instance" do
      subject { PaperTrail::Version.new(attributes) rescue PaperTrail::Version.new }

      describe '#paper_trail_originator' do
        it { is_expected.to respond_to(:paper_trail_originator) }

        context "No previous versions" do
          specify { expect(subject.previous).to be_nil }

          it "should return nil" do
            expect(subject.paper_trail_originator).to be_nil
          end
        end

        context "Has previous version", :versioning => true do
          let(:name) { Faker::Name.name }
          let(:widget) { Widget.create!(name: Faker::Name.name) }
          before do
            widget.versions.first.update_attributes!(:whodunnit => name)
            widget.update_attributes!(name: Faker::Name.first_name)
          end
          subject { widget.versions.last }

          specify { expect(subject.previous).to be_instance_of(PaperTrail::Version) }

          it "should return nil" do
            expect(subject.paper_trail_originator).to eq(name)
          end
        end
      end

      describe "#originator" do
        it { is_expected.to respond_to(:originator) }
        let(:warning_msg) do
          "DEPRECATED: use `paper_trail_originator` instead of `originator`." +
          " Support for `originator` will be removed in PaperTrail 4.0"
        end

        it 'should set the invoke `paper_trail_originator`' do
          is_expected.to receive(:warn)
          is_expected.to receive(:paper_trail_originator)
          subject.originator
        end

        it 'should display a deprecation warning' do
          is_expected.to receive(:warn).with(warning_msg)
          subject.originator
        end
      end

      describe '#terminator' do
        it { should respond_to(:terminator) }

        let(:attributes) { {:whodunnit => Faker::Name.first_name} }

        it "is an alias for the `whodunnit` attribute" do
          subject.terminator.should == attributes[:whodunnit]
        end
      end

      describe :version_author do
        it { should respond_to(:version_author) }

        it "should be an alias for the `terminator` method" do
          subject.method(:version_author).should == subject.method(:terminator)
        end
      end
    end

    describe "Class" do
      describe :where_object do
        it { PaperTrail::Version.should respond_to(:where_object) }

        context "invalid arguments" do
          it "should raise an error" do
            expect { PaperTrail::Version.where_object(:foo) }.to raise_error(ArgumentError)
            expect { PaperTrail::Version.where_object([]) }.to raise_error(ArgumentError)
          end
        end

        context "valid arguments", :versioning => true do
          let(:widget) { Widget.new }
          let(:name) { Faker::Name.first_name }
          let(:int) { rand(10) + 1 }

          before do
            widget.update_attributes!(:name => name, :an_integer => int)
            widget.update_attributes!(:name => 'foobar', :an_integer => 100)
            widget.update_attributes!(:name => Faker::Name.last_name, :an_integer => 15)
          end

          context "`serializer == YAML`" do
            specify { PaperTrail.serializer == PaperTrail::Serializers::YAML }

            it "should be able to locate versions according to their `object` contents" do
              PaperTrail::Version.where_object(:name => name).should == [widget.versions[1]]
              PaperTrail::Version.where_object(:an_integer => 100).should == [widget.versions[2]]
            end
          end

          context "`serializer == JSON`" do
            before { PaperTrail.serializer = PaperTrail::Serializers::JSON }
            specify { PaperTrail.serializer == PaperTrail::Serializers::JSON }

            it "should be able to locate versions according to their `object` contents" do
              PaperTrail::Version.where_object(:name => name).should == [widget.versions[1]]
              PaperTrail::Version.where_object(:an_integer => 100).should == [widget.versions[2]]
            end
          end
        end
      end
    end
  end
end
