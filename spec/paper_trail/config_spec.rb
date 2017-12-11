# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe Config do
    describe ".instance" do
      it "returns the singleton instance" do
        expect { described_class.instance }.not_to raise_error
      end
    end

    describe ".new" do
      it "raises NoMethodError" do
        expect { described_class.new }.to raise_error(NoMethodError)
      end
    end

    describe "track_associations?" do
      context "@track_associations is nil" do
        it "returns false and prints a deprecation warning" do
          config = described_class.instance
          config.track_associations = nil
          expect(config.track_associations?).to eq(false)
        end

        after do
          PaperTrail.config.track_associations = true
        end
      end
    end

    describe ".version_limit", versioning: true do
      after { PaperTrail.config.version_limit = nil }

      it "limits the number of versions to 3 (2 plus the created at event)" do
        PaperTrail.config.version_limit = 2
        widget = Widget.create!(name: "Henry")
        6.times { widget.update_attribute(:name, FFaker::Lorem.word) }
        expect(widget.versions.first.event).to(eq("create"))
        expect(widget.versions.size).to(eq(3))
      end
    end
  end
end
