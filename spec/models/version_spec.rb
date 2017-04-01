require "rails_helper"

describe PaperTrail::Version, type: :model do
  it "should include the `VersionConcern` module to get base functionality" do
    expect(PaperTrail::Version).to include(PaperTrail::VersionConcern)
  end

  describe "Attributes" do
    describe "object_changes column", versioning: true do
      let(:widget) { Widget.create!(name: "Dashboard") }
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

  describe "Methods" do
    describe "Instance" do
      subject { PaperTrail::Version.new }

      describe "#paper_trail_originator" do
        it { is_expected.to respond_to(:paper_trail_originator) }

        context "No previous versions" do
          specify { expect(subject.previous).to be_nil }

          it "should return nil" do
            expect(subject.paper_trail_originator).to be_nil
          end
        end

        context "Has previous version", versioning: true do
          subject { widget.versions.last }

          let(:name) { FFaker::Name.name }
          let(:widget) { Widget.create!(name: FFaker::Name.name) }

          before do
            widget.versions.first.update_attributes!(whodunnit: name)
            widget.update_attributes!(name: FFaker::Name.first_name)
          end

          specify { expect(subject.previous).to be_instance_of(PaperTrail::Version) }

          it "should return nil" do
            expect(subject.paper_trail_originator).to eq(name)
          end
        end
      end

      describe "#originator" do
        it { is_expected.to respond_to(:originator) }

        it "should set the invoke `paper_trail_originator`" do
          allow(ActiveSupport::Deprecation).to receive(:warn)
          is_expected.to receive(:paper_trail_originator)
          subject.originator
        end

        it "should display a deprecation warning" do
          expect(ActiveSupport::Deprecation).to receive(:warn).
            with(/Use paper_trail_originator instead of originator/)
          subject.originator
        end
      end

      describe "#terminator" do
        subject { PaperTrail::Version.new attributes }

        let(:attributes) { { whodunnit: FFaker::Name.first_name } }

        it { is_expected.to respond_to(:terminator) }

        it "is an alias for the `whodunnit` attribute" do
          expect(subject.terminator).to eq(attributes[:whodunnit])
        end
      end

      describe "#version_author" do
        it { is_expected.to respond_to(:version_author) }

        it "should be an alias for the `terminator` method" do
          expect(subject.method(:version_author)).to eq(subject.method(:terminator))
        end
      end
    end

    describe "Class" do
      column_overrides = [false]
      if ENV["DB"] == "postgres" && ::ActiveRecord::VERSION::MAJOR >= 4
        column_overrides << "json"
        # 'jsonb' column types are only supported for ActiveRecord 4.2+
        column_overrides << "jsonb" if ::ActiveRecord::VERSION::STRING >= "4.2"
      end

      column_overrides.shuffle.each do |override|
        context "with a #{override || 'text'} column" do
          before do
            if override
              ActiveRecord::Base.connection.execute("SAVEPOINT pgtest;")
              %w(object object_changes).each do |column|
                ActiveRecord::Base.connection.execute(
                  "ALTER TABLE versions DROP COLUMN #{column};"
                )
                ActiveRecord::Base.connection.execute(
                  "ALTER TABLE versions ADD COLUMN #{column} #{override};"
                )
              end
              PaperTrail::Version.reset_column_information
            end
          end
          after do
            if override
              ActiveRecord::Base.connection.execute("ROLLBACK TO SAVEPOINT pgtest;")
              PaperTrail::Version.reset_column_information
            end
          end

          describe "#where_object" do
            it { expect(PaperTrail::Version).to respond_to(:where_object) }

            context "invalid arguments" do
              it "should raise an error" do
                expect {
                  PaperTrail::Version.where_object(:foo)
                }.to raise_error(ArgumentError)
                expect {
                  PaperTrail::Version.where_object([])
                }.to raise_error(ArgumentError)
              end
            end

            context "valid arguments", versioning: true do
              let(:widget) { Widget.new }
              let(:name) { FFaker::Name.first_name }
              let(:int) { rand(10) + 1 }

              before do
                widget.update_attributes!(name: name, an_integer: int)
                widget.update_attributes!(name: "foobar", an_integer: 100)
                widget.update_attributes!(name: FFaker::Name.last_name, an_integer: 15)
              end

              context "`serializer == YAML`" do
                specify do
                  expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML
                end

                it "should be able to locate versions according to their `object` contents" do
                  expect(
                    PaperTrail::Version.where_object(name: name)
                  ).to eq([widget.versions[1]])
                  expect(
                    PaperTrail::Version.where_object(an_integer: 100)
                  ).to eq([widget.versions[2]])
                end
              end

              context "JSON serializer" do
                before(:all) do
                  PaperTrail.serializer = PaperTrail::Serializers::JSON
                end

                specify do
                  expect(PaperTrail.serializer).to be PaperTrail::Serializers::JSON
                end

                it "should be able to locate versions according to their `object` contents" do
                  expect(
                    PaperTrail::Version.where_object(name: name)
                  ).to eq([widget.versions[1]])
                  expect(
                    PaperTrail::Version.where_object(an_integer: 100)
                  ).to eq([widget.versions[2]])
                end

                after(:all) do
                  PaperTrail.serializer = PaperTrail::Serializers::YAML
                end
              end
            end
          end

          describe "#where_object_changes" do
            context "invalid arguments" do
              it "should raise an error" do
                expect {
                  PaperTrail::Version.where_object_changes(:foo)
                }.to raise_error(ArgumentError)
                expect {
                  PaperTrail::Version.where_object_changes([])
                }.to raise_error(ArgumentError)
              end
            end

            context "valid arguments", versioning: true do
              let(:widget) { Widget.new }
              let(:name) { FFaker::Name.first_name }
              let(:int) { rand(5) + 2 }

              before do
                widget.update_attributes!(name: name, an_integer: 0)
                widget.update_attributes!(name: "foobar", an_integer: 77)
                widget.update_attributes!(name: FFaker::Name.last_name, an_integer: int)
              end

              context "YAML serializer" do
                specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML }

                it "locates versions according to their `object_changes` contents" do
                  expect(
                    widget.versions.where_object_changes(name: name)
                  ).to eq(widget.versions[0..1])
                  expect(
                    widget.versions.where_object_changes(an_integer: 77)
                  ).to eq(widget.versions[1..2])
                  expect(
                    widget.versions.where_object_changes(an_integer: int)
                  ).to eq([widget.versions.last])
                end

                it "handles queries for multiple attributes" do
                  expect(
                    widget.versions.where_object_changes(an_integer: 77, name: "foobar")
                  ).to eq(widget.versions[1..2])
                end
              end

              context "JSON serializer" do
                before(:all) { PaperTrail.serializer = PaperTrail::Serializers::JSON }
                specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::JSON }

                it "locates versions according to their `object_changes` contents" do
                  expect(
                    widget.versions.where_object_changes(name: name)
                  ).to eq(widget.versions[0..1])
                  expect(
                    widget.versions.where_object_changes(an_integer: 77)
                  ).to eq(widget.versions[1..2])
                  expect(
                    widget.versions.where_object_changes(an_integer: int)
                  ).to eq([widget.versions.last])
                end

                it "handles queries for multiple attributes" do
                  expect(
                    widget.versions.where_object_changes(an_integer: 77, name: "foobar")
                  ).to eq(widget.versions[1..2])
                end

                after(:all) { PaperTrail.serializer = PaperTrail::Serializers::YAML }
              end
            end
          end
        end
      end
    end
  end
end
