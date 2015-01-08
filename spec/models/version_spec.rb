require 'rails_helper'

describe PaperTrail::Version, :type => :model do
  it "should include the `VersionConcern` module to get base functionality" do
    expect(PaperTrail::Version).to include(PaperTrail::VersionConcern)
  end

  describe "Attributes" do
    it { is_expected.to have_db_column(:item_type).of_type(:string) }
    it { is_expected.to have_db_column(:item_id).of_type(:integer) }
    it { is_expected.to have_db_column(:event).of_type(:string) }
    it { is_expected.to have_db_column(:whodunnit).of_type(:string) }
    it { is_expected.to have_db_column(:object).of_type(:text) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }

    describe "object_changes column", :versioning => true do
      let(:widget) { Widget.create!(:name => 'Dashboard') }
      let(:value) { widget.versions.last.object_changes }

      context "serializer is YAML" do
        specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML }

        it "should store out as a plain hash" do
          expect(value =~ /HashWithIndifferentAccess/).to be_nil
        end
      end

      context "serializer is JSON" do
        before(:all) { PaperTrail.serializer = PaperTrail::Serializers::JSON }

        it "should store out as a plain hash" do
          expect(value =~ /HashWithIndifferentAccess/).to be_nil
        end

        after(:all) { PaperTrail.serializer = PaperTrail::Serializers::YAML }
      end
    end
  end

  describe "Indexes" do
    it { is_expected.to have_db_index([:item_type, :item_id]) }
  end

  describe "Methods" do
    describe "Instance" do
      subject { PaperTrail::Version.new(attributes) rescue PaperTrail::Version.new }

      describe '#terminator' do
        it { is_expected.to respond_to(:terminator) }

        let(:attributes) { {:whodunnit => Faker::Name.first_name} }

        it "is an alias for the `whodunnit` attribute" do
          expect(subject.whodunnit).to eq(attributes[:whodunnit])
        end
      end

      describe '#version_author' do
        it { is_expected.to respond_to(:version_author) }

        it "should be an alias for the `terminator` method" do
          expect(subject.method(:version_author)).to eq(subject.method(:terminator))
        end
      end
    end

    describe "Class" do
      describe '#where_object' do
        it { expect(PaperTrail::Version).to respond_to(:where_object) }

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
            specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML }

            it "should be able to locate versions according to their `object` contents" do
              expect(PaperTrail::Version.where_object(:name => name)).to eq([widget.versions[1]])
              expect(PaperTrail::Version.where_object(:an_integer => 100)).to eq([widget.versions[2]])
            end
          end

          context "`serializer == JSON`" do
            before(:all) { PaperTrail.serializer = PaperTrail::Serializers::JSON }
            specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::JSON }

            it "should be able to locate versions according to their `object` contents" do
              expect(PaperTrail::Version.where_object(:name => name)).to eq([widget.versions[1]])
              expect(PaperTrail::Version.where_object(:an_integer => 100)).to eq([widget.versions[2]])
            end

            after(:all) { PaperTrail.serializer = PaperTrail::Serializers::YAML }
          end
        end
      end

      describe '#where_object_changes' do
        it { expect(PaperTrail::Version).to respond_to(:where_object_changes) }

        context "invalid arguments" do
          it "should raise an error" do
            expect { PaperTrail::Version.where_object_changes(:foo) }.to raise_error(ArgumentError)
            expect { PaperTrail::Version.where_object_changes([]) }.to raise_error(ArgumentError)
          end
        end

        context "valid arguments", :versioning => true do
          let(:widget) { Widget.new }
          let(:name) { Faker::Name.first_name }
          let(:int) { rand(10) + 1 }

          before do
            widget.update_attributes!(:name => name, :an_integer => 0)
            widget.update_attributes!(:name => 'foobar', :an_integer => 100)
            widget.update_attributes!(:name => Faker::Name.last_name, :an_integer => int)
          end

          context "`serializer == YAML`" do
            specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML }

            it "should be able to locate versions according to their `object_changes` contents" do
              expect(PaperTrail::Version.where_object_changes(:name => name)).to eq(widget.versions[0..1])
              expect(PaperTrail::Version.where_object_changes(:an_integer => 100)).to eq(widget.versions[1..2])
              expect(PaperTrail::Version.where_object_changes(:an_integer => int)).to eq([widget.versions.last])
            end

            it "should be able to handle queries for multiple attributes" do
              expect(PaperTrail::Version.where_object_changes(:an_integer => 100, :name => 'foobar')).to eq(widget.versions[1..2])
            end
          end

          context "`serializer == JSON`" do
            before(:all) { PaperTrail.serializer = PaperTrail::Serializers::JSON }
            specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::JSON }

            it "should be able to locate versions according to their `object_changes` contents" do
              expect(PaperTrail::Version.where_object_changes(:name => name)).to eq(widget.versions[0..1])
              expect(PaperTrail::Version.where_object_changes(:an_integer => 100)).to eq(widget.versions[1..2])
              expect(PaperTrail::Version.where_object_changes(:an_integer => int)).to eq([widget.versions.last])
            end

            it "should be able to handle queries for multiple attributes" do
              expect(PaperTrail::Version.where_object_changes(:an_integer => 100, :name => 'foobar')).to eq(widget.versions[1..2])
            end

            after(:all) { PaperTrail.serializer = PaperTrail::Serializers::YAML }
          end
        end
      end

      describe '#recent_history' do
        context "invalid arguments" do
          it "should raise an error" do
            expect { PaperTrail::Version.recent_history(:foo) }.to raise_error(ArgumentError)
          end
        end

        context "valid arguments", :versioning => true do
          let(:widget) { Widget.new }

          before do
            3.times { widget.update_attributes!(:name => "a#{widget.name}") }
          end

          it "orders the recent history" do
            expect(PaperTrail::Version.recent_history(1).first.object_changes).to include('aaa')
          end
        end
      end
    end
  end
end
