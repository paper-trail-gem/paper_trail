# frozen_string_literal: true

require "spec_helper"

RSpec.describe NoObject, :versioning do
  it "still creates version records" do
    n = described_class.create!(letter: "A")
    a = n.versions.last.attributes
    expect(a).not_to include "object"
    expect(a["event"]).to eq "create"
    expect(a["object_changes"]).to start_with("---")
    expect(a["metadatum"]).to eq(42)

    n.update!(letter: "B")
    a = n.versions.last.attributes
    expect(a).not_to include "object"
    expect(a["event"]).to eq "update"
    expect(a["object_changes"]).to start_with("---")
    expect(a["metadatum"]).to eq(42)

    n.destroy!
    a = n.versions.last.attributes
    expect(a).not_to include "object"
    expect(a["event"]).to eq "destroy"
    expect(a["object_changes"]).to start_with("---")
    expect(a["metadatum"]).to eq(42)

    # New feature: destroy populates object_changes
    # https://github.com/paper-trail-gem/paper_trail/pull/1123
    h = if YAML.respond_to?(:unsafe_load)
          YAML.unsafe_load a["object_changes"]
        else
          YAML.load a["object_changes"]
        end
    expect(h["id"]).to eq([n.id, nil])
    expect(h["letter"]).to eq([n.letter, nil])
    expect(h["created_at"][0]).to be_present
    expect(h["created_at"][1]).to be_nil
    expect(h["updated_at"][0]).to be_present
    expect(h["updated_at"][1]).to be_nil
  end

  describe "reify" do
    it "raises error" do
      n = described_class.create!(letter: "A")
      v = n.versions.last
      expect { v.reify }.to(
        raise_error(
          PaperTrail::Error,
          "reify requires an object column"
        )
      )
    end
  end

  describe "where_object" do
    it "raises error" do
      n = described_class.create!(letter: "A")
      expect {
        n.versions.where_object(foo: "bar")
      }.to(
        raise_error(
          PaperTrail::Error,
          "where_object requires an object column"
        )
      )
    end
  end
end
