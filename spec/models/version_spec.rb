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

    describe "#reload", :versioning do
      it "clears the memoized changeset" do
        version = Widget.create!(name: "Alice").versions.last
        expect(version.changeset["name"]).to eq([nil, "Alice"])

        # e.g. a job that redacts personal data
        described_class.where(id: version.id).update_all(
          object_changes: PaperTrail.serializer.dump("name" => [nil, "[FILTERED]"])
        )
        expect(version.reload.changeset).to eq("name" => [nil, "[FILTERED]"])
      end

      it "returns the reloaded whodunnit from terminator and version_author" do
        widget = PaperTrail.request(whodunnit: "alice") { Widget.create!(name: "A") }
        version = widget.versions.last
        expect(version.terminator).to eq("alice")

        described_class.find(version.id).update!(whodunnit: "bob")
        version.reload
        expect(version.terminator).to eq("bob")
        expect(version.version_author).to eq("bob")
      end

      it "clears memos that depend on item_id" do
        keep = Widget.create!(name: "Keep")
        dupe = Widget.create!(name: "Dupe")
        dupe.update!(name: "Dupe 2")
        version = dupe.versions.last
        expect(version.index).to eq(1)

        # e.g. merging duplicate records
        described_class.where(item_type: "Widget", item_id: dupe.id).update_all(item_id: keep.id)
        expect(version.reload.index).to eq(2)
      end

      context "when a sibling version is deleted" do
        let(:widget) do
          PaperTrail.request(whodunnit: "alice") { Widget.create!(name: "A") }.tap do |w|
            PaperTrail.request(whodunnit: "bob") { w.update!(name: "B") }
            PaperTrail.request(whodunnit: "carol") { w.update!(name: "C") }
          end
        end
        let(:first_version) { widget.versions.first }
        let(:middle_version) { widget.versions.second }
        let(:last_version) { widget.versions.last }

        # As in the README's "Deleting Old Versions"
        def delete_middle_version
          described_class.where(id: middle_version.id).delete_all
        end

        it "clears the memoized next" do
          expect(first_version.next).to eq(middle_version)
          delete_middle_version
          expect(first_version.reload.next).to eq(last_version)
        end

        it "clears the memoized previous and paper_trail_originator" do
          expect(last_version.previous).to eq(middle_version)
          expect(last_version.paper_trail_originator).to eq("bob")
          delete_middle_version
          last_version.reload
          expect(last_version.previous).to eq(first_version)
          expect(last_version.paper_trail_originator).to eq("alice")
        end

        it "clears the memoized index" do
          expect(last_version.index).to eq(2)
          delete_middle_version
          expect(last_version.reload.index).to eq(1)
        end
      end
    end

    describe "#terminator" do
      it "is an alias for the `whodunnit` attribute" do
        attributes = { whodunnit: FFaker::Name.first_name }
        version = described_class.new(attributes)
        expect(version.terminator).to eq(attributes[:whodunnit])
      end

      it "returns the current whodunnit after it is updated", :versioning do
        widget = PaperTrail.request(whodunnit: "alice") { Widget.create!(name: "A") }
        version = widget.versions.last
        expect(version.terminator).to eq("alice")

        version.update!(whodunnit: "bob")
        expect(version.terminator).to eq("bob")
        expect(version.version_author).to eq("bob")
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
