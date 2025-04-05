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
