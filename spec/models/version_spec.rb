require "spec_helper"

module PaperTrail
  ::RSpec.describe Version, type: :model do
    describe "object_changes column", versioning: true do
      let(:widget) { Widget.create!(name: "Dashboard") }
      let(:value) { widget.versions.last.object_changes }

      context "serializer is YAML" do
        specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML }

        it "store out as a plain hash" do
          expect(value =~ /HashWithIndifferentAccess/).to be_nil
        end
      end

      context "serializer is JSON" do
        before do
          PaperTrail.serializer = PaperTrail::Serializers::JSON
        end

        it "store out as a plain hash" do
          expect(value =~ /HashWithIndifferentAccess/).to be_nil
        end

        after do
          PaperTrail.serializer = PaperTrail::Serializers::YAML
        end
      end
    end

    describe "#paper_trail_originator" do
      context "no previous versions" do
        it "returns nil" do
          expect(PaperTrail::Version.new.paper_trail_originator).to be_nil
        end
      end

      context "has previous version", versioning: true do
        it "returns name of whodunnit" do
          name = FFaker::Name.name
          widget = Widget.create!(name: FFaker::Name.name)
          widget.versions.first.update_attributes!(whodunnit: name)
          widget.update_attributes!(name: FFaker::Name.first_name)
          expect(widget.versions.last.paper_trail_originator).to eq(name)
        end
      end
    end

    describe "#previous" do
      context "no previous versions" do
        it "returns nil" do
          expect(PaperTrail::Version.new.previous).to be_nil
        end
      end

      context "has previous version", versioning: true do
        it "returns a PaperTrail::Version" do
          name = FFaker::Name.name
          widget = Widget.create!(name: FFaker::Name.name)
          widget.versions.first.update_attributes!(whodunnit: name)
          widget.update_attributes!(name: FFaker::Name.first_name)
          expect(widget.versions.last.previous).to be_instance_of(PaperTrail::Version)
        end
      end
    end

    describe "#terminator" do
      it "is an alias for the `whodunnit` attribute" do
        attributes = { whodunnit: FFaker::Name.first_name }
        version = PaperTrail::Version.new(attributes)
        expect(version.terminator).to eq(attributes[:whodunnit])
      end
    end

    describe "#version_author" do
      it "is an alias for the `terminator` method" do
        version = PaperTrail::Version.new
        expect(version.method(:version_author)).to eq(version.method(:terminator))
      end
    end

    context "changing the data type of database columns on the fly" do
      # TODO: Changing the data type of these database columns in the middle
      # of the test suite adds a fair amount of complication. Is there a better
      # way? We already have a `json_versions` table in our tests, maybe we
      # could use that and add a `jsonb_versions` table?
      column_overrides = [false]
      if ENV["DB"] == "postgres" && ::ActiveRecord::VERSION::MAJOR >= 4
        column_overrides << "json"
        # 'jsonb' column types are only supported for ActiveRecord 4.2+
        column_overrides << "jsonb" if ::ActiveRecord::VERSION::STRING >= "4.2"
      end

      column_overrides.shuffle.each do |column_datatype_override|
        context "with a #{column_datatype_override || 'text'} column" do
          let(:widget) { Widget.new }
          let(:name) { FFaker::Name.first_name }
          let(:int) { column_datatype_override ? 1 : rand(5) + 2 }

          before do
            if column_datatype_override
              # In rails < 5, we use truncation, ie. there is no transaction
              # around the tests, so we can't use a savepoint.
              if active_record_gem_version >= ::Gem::Version.new("5")
                ActiveRecord::Base.connection.execute("SAVEPOINT pgtest;")
              end
              %w[object object_changes].each do |column|
                ActiveRecord::Base.connection.execute(
                  "ALTER TABLE versions DROP COLUMN #{column};"
                )
                ActiveRecord::Base.connection.execute(
                  "ALTER TABLE versions ADD COLUMN #{column} #{column_datatype_override};"
                )
              end
              PaperTrail::Version.reset_column_information
            end
          end

          after do
            PaperTrail.serializer = PaperTrail::Serializers::YAML

            if column_datatype_override
              # In rails < 5, we use truncation, ie. there is no transaction
              # around the tests, so we can't use a savepoint.
              if active_record_gem_version >= ::Gem::Version.new("5")
                ActiveRecord::Base.connection.execute("ROLLBACK TO SAVEPOINT pgtest;")
              else
                %w[object object_changes].each do |column|
                  ActiveRecord::Base.connection.execute(
                    "ALTER TABLE versions DROP COLUMN #{column};"
                  )
                  ActiveRecord::Base.connection.execute(
                    "ALTER TABLE versions ADD COLUMN #{column} text;"
                  )
                end
              end
              PaperTrail::Version.reset_column_information
            end
          end

          describe "#where_object", versioning: true do
            it "requires its argument to be a Hash" do
              widget.update_attributes!(name: name, an_integer: int)
              widget.update_attributes!(name: "foobar", an_integer: 100)
              widget.update_attributes!(name: FFaker::Name.last_name, an_integer: 15)
              expect {
                PaperTrail::Version.where_object(:foo)
              }.to raise_error(ArgumentError)
              expect {
                PaperTrail::Version.where_object([])
              }.to raise_error(ArgumentError)
            end

            context "YAML serializer" do
              it "locates versions according to their `object` contents" do
                expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML
                widget.update_attributes!(name: name, an_integer: int)
                widget.update_attributes!(name: "foobar", an_integer: 100)
                widget.update_attributes!(name: FFaker::Name.last_name, an_integer: 15)
                expect(
                  PaperTrail::Version.where_object(an_integer: int)
                ).to eq([widget.versions[1]])
                expect(
                  PaperTrail::Version.where_object(name: name)
                ).to eq([widget.versions[1]])
                expect(
                  PaperTrail::Version.where_object(an_integer: 100)
                ).to eq([widget.versions[2]])
              end
            end

            context "JSON serializer" do
              it "locates versions according to their `object` contents" do
                PaperTrail.serializer = PaperTrail::Serializers::JSON
                expect(PaperTrail.serializer).to be PaperTrail::Serializers::JSON
                widget.update_attributes!(name: name, an_integer: int)
                widget.update_attributes!(name: "foobar", an_integer: 100)
                widget.update_attributes!(name: FFaker::Name.last_name, an_integer: 15)
                expect(
                  PaperTrail::Version.where_object(an_integer: int)
                ).to eq([widget.versions[1]])
                expect(
                  PaperTrail::Version.where_object(name: name)
                ).to eq([widget.versions[1]])
                expect(
                  PaperTrail::Version.where_object(an_integer: 100)
                ).to eq([widget.versions[2]])
              end
            end
          end

          describe "#where_object_changes", versioning: true do
            it "requires its argument to be a Hash" do
              expect {
                PaperTrail::Version.where_object_changes(:foo)
              }.to raise_error(ArgumentError)
              expect {
                PaperTrail::Version.where_object_changes([])
              }.to raise_error(ArgumentError)
            end

            # Only test json and jsonb columns. where_object_changes no longer
            # supports text columns.
            if column_datatype_override
              it "locates versions according to their object_changes contents" do
                widget.update_attributes!(name: name, an_integer: 0)
                widget.update_attributes!(name: "foobar", an_integer: 100)
                widget.update_attributes!(name: FFaker::Name.last_name, an_integer: int)
                expect(
                  widget.versions.where_object_changes(name: name)
                ).to eq(widget.versions[0..1])
                expect(
                  widget.versions.where_object_changes(an_integer: 100)
                ).to eq(widget.versions[1..2])
                expect(
                  widget.versions.where_object_changes(an_integer: int)
                ).to eq([widget.versions.last])
                expect(
                  widget.versions.where_object_changes(an_integer: 100, name: "foobar")
                ).to eq(widget.versions[1..2])
              end
            else
              it "raises error" do
                expect {
                  widget.versions.where_object_changes(name: "foo").to_a
                }.to(raise_error(/no longer supports reading YAML from a text column/))
              end
            end
          end
        end
      end
    end
  end
end
