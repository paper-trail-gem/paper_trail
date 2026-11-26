# frozen_string_literal: true

require "spec_helper"
require "support/shared_examples/queries"
require "support/shared_examples/active_record_encryption"
require "support/custom_object_changes_adapter"

module PaperTrail
  ::RSpec.describe Version do
    describe "#object_changes", :versioning do
      let(:widget) { Widget.create!(name: "Dashboard") }
      let(:value) { widget.versions.last.object_changes }

      context "when serializer is YAML" do
        specify { expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML }

        it "store out as a plain hash" do
          expect(value).not_to include("HashWithIndifferentAccess")
        end
      end

      context "with object_changes_adapter" do
        after do
          PaperTrail.config.object_changes_adapter = nil
        end

        it "creates a version with custom changes" do
          adapter = instance_spy(CustomObjectChangesAdapter)
          PaperTrail.config.object_changes_adapter = adapter
          custom_changes_value = [["name", nil, "Dashboard"]]
          allow(adapter).to(
            receive(:diff).with(
              hash_including("name" => [nil, "Dashboard"])
            ).and_return(custom_changes_value)
          )
          yaml = widget.versions.last.object_changes
          expect(YAML.load(yaml)).to eq(custom_changes_value)
          expect(adapter).to have_received(:diff)
        end

        it "defaults to the original behavior" do
          adapter = Class.new.new
          PaperTrail.config.object_changes_adapter = adapter
          expect(widget.versions.last.object_changes).to start_with("---")
        end
      end

      context "when serializer is JSON" do
        before do
          PaperTrail.serializer = PaperTrail::Serializers::JSON
        end

        after do
          PaperTrail.serializer = PaperTrail::Serializers::YAML
        end

        it "store out as a plain hash" do
          expect(value).not_to include("HashWithIndifferentAccess")
        end
      end
    end

    describe "#changeset", :versioning do
      let(:widget) do
        Widget.create!(name: "Henry   Jones").tap { |w| w.update!(name: "Henry Jones") }
      end
      let(:version) { widget.versions.last }

      it "returns a HashWithIndifferentAccess" do
        expect(version.changeset).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(version.changeset[:name]).to eq(["Henry   Jones", "Henry Jones"])
      end

      it "loads the changeset only once" do
        allow(version).to receive(:load_changeset).and_call_original
        2.times { version.changeset }
        expect(version).to have_received(:load_changeset).once
      end

      # https://github.com/paper-trail-gem/paper_trail/issues/1508
      it "is not affected by in-place changes to a string it returned" do
        version.changeset["name"].first.squeeze!(" ")
        expect(version.changeset["name"]).to eq(["Henry   Jones", "Henry Jones"])
        expect(version.changeset).to eq(version.item.versions.last.changeset)
      end

      it "is not affected by replacing an element of an array it returned" do
        version.changeset["name"][0] = "Indiana Jones"
        expect(version.changeset["name"]).to eq(["Henry   Jones", "Henry Jones"])
      end

      it "is not affected by removing a key from the hash it returned" do
        version.changeset.delete("name")
        expect(version.changeset).to have_key("name")
      end

      it "returns other values, such as a cached TimeZone, as they are" do
        person = Person.create!(time_zone: "Samoa")
        time_zone = person.versions.last.changeset[:time_zone].last
        expect(time_zone).to equal(ActiveSupport::TimeZone["Samoa"])
      end

      context "with an object_changes_adapter that implements load_changeset" do
        before do
          adapter = Class.new do
            def load_changeset(_version)
              { "name" => ["Henry   Jones", "Henry Jones"] }
            end
          end
          PaperTrail.config.object_changes_adapter = adapter.new
        end

        after do
          PaperTrail.config.object_changes_adapter = nil
        end

        it "is not affected by changes to the hash it returned" do
          version.changeset.delete("name")
          expect(version.changeset).to eq("name" => ["Henry   Jones", "Henry Jones"])
        end
      end

      if ENV["DB"] == "postgres"
        context "with a json object_changes column" do
          it "does not let changes to the changeset alter object_changes" do
            fruit = Fruit.create!(name: "Pink   Lady")
            fruit.update!(name: "Pink Lady")
            fruit_version = fruit.versions.last
            fruit_version.changeset["name"].first.squeeze!(" ")
            expect(fruit_version.object_changes["name"]).to eq(["Pink   Lady", "Pink Lady"])
            expect(fruit_version).not_to be_changed
          end
        end
      end
    end

    describe "#paper_trail_originator" do
      context "with no previous versions" do
        it "returns nil" do
          expect(described_class.new.paper_trail_originator).to be_nil
        end
      end

      context "with previous version", :versioning do
        it "returns name of whodunnit" do
          name = FFaker::Name.name
          widget = Widget.create!(name: FFaker::Name.name)
          widget.versions.first.update!(whodunnit: name)
          widget.update!(name: FFaker::Name.first_name)
          expect(widget.versions.last.paper_trail_originator).to eq(name)
        end
      end
    end

    describe "#previous" do
      context "with no previous versions" do
        it "returns nil" do
          expect(described_class.new.previous).to be_nil
        end
      end

      context "with previous version", :versioning do
        it "returns a PaperTrail::Version" do
          name = FFaker::Name.name
          widget = Widget.create!(name: FFaker::Name.name)
          widget.versions.first.update!(whodunnit: name)
          widget.update!(name: FFaker::Name.first_name)
          expect(widget.versions.last.previous).to be_instance_of(described_class)
        end
      end
    end

    describe "#terminator" do
      it "is an alias for the `whodunnit` attribute" do
        attributes = { whodunnit: FFaker::Name.first_name }
        version = described_class.new(attributes)
        expect(version.terminator).to eq(attributes[:whodunnit])
      end
    end

    describe "#version_author" do
      it "is an alias for the `terminator` method" do
        version = described_class.new
        expect(version.method(:version_author)).to eq(version.method(:terminator))
      end
    end

    context "with text columns", :versioning do
      include_examples "queries", :text, ::Widget, :an_integer
    end

    if ENV["DB"] == "postgres"
      context "with json columns", :versioning do
        include_examples(
          "queries",
          :json,
          ::Fruit, # uses JsonVersion
          :mass
        )

        include_examples("active_record_encryption", ::Fruit)
      end

      context "with jsonb columns", :versioning do
        include_examples(
          "queries",
          :jsonb,
          ::Vegetable, # uses JsonbVersion
          :mass
        )

        include_examples("active_record_encryption", ::Vegetable)
      end
    end
  end
end
