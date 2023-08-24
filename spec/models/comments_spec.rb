# frozen_string_literal: true

require "spec_helper"

RSpec.describe Comment, versioning: true do
  after do
    Timecop.return
  end

  context "with debouncing enabled" do
    it "overwrites existing updates within debounce period" do
      comment = described_class.create(body: "f")

      Timecop.freeze(Time.current)
      comment.update(body: "foo")
      Timecop.travel(Time.current + 0.5.seconds)
      comment.update(body: "foobar")

      expect(comment.versions.count).to eq(2)

      last_changes = PaperTrail.serializer.load(comment.versions.last.object_changes)
      expect(last_changes).to include({ "body" => %w[f foobar] })
    end

    it "makes each subsequent update outside of debounce window" do
      comment = described_class.create(body: "f")

      Timecop.freeze(Time.current)
      comment.update(body: "foo")
      Timecop.travel(Time.current + 1.1.seconds)
      comment.update(body: "foobar")

      expect(comment.versions.count).to eq(3)

      last_changes = PaperTrail.serializer.load(comment.versions.last.object_changes)
      expect(last_changes).to include({ "body" => %w[foo foobar] })
    end

    it "handle merge with new items" do
      comment = described_class.create(body: "f")

      comment.update(body: "foo")
      Timecop.travel(Time.current + 0.5.seconds)
      comment.update(author_name: "Greg")

      expect(comment.versions.count).to eq(2)

      last_changes = PaperTrail.serializer.load(comment.versions.last.object_changes)
      expect(last_changes).to include({ "author_name" => [nil, "Greg"], "body" => %w[f foo] })
    end

    it "handle nil in first update" do
      comment = described_class.create(body: "f")

      comment.update(body: "foo")
      Timecop.travel(Time.current + 0.5.seconds)
      comment.update(author_name: "Greg")
      comment.update(author_name: "Gregory")

      expect(comment.versions.count).to eq(2)

      last_changes = PaperTrail.serializer.load(comment.versions.last.object_changes)
      expect(last_changes).to include({ "author_name" => [nil, "Gregory"], "body" => %w[f foo] })
    end

    it "handles ignored updates" do
      comment = described_class.create(body: "f", flagged: false)

      Timecop.freeze(Time.current)
      comment.update(body: "foo") # Valid update event
      comment.update(flagged: true) # Ignored version

      expect(comment.versions.count).to eq(2)
    end
  end
end
