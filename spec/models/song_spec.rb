# frozen_string_literal: true

require "spec_helper"

::RSpec.describe(::Song, type: :model, versioning: true) do
  describe "#joins" do
    it "works" do
      described_class.create!
      result = described_class.
        joins(:versions).
        select("songs.id, max(versions.event) as event").
        group("songs.id").
        first
      expect(result.event).to eq("create")
    end
  end
end
