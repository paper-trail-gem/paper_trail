# frozen_string_literal: true

require "spec_helper"

RSpec.describe NoObject, versioning: true do
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
    expect(a["object_changes"]).to be_nil
    expect(a["metadatum"]).to eq(42)
  end

  describe "reify" do
    it "raises error" do
      n = NoObject.create!(letter: "A")
      v = n.versions.last
      expect { v.reify }.to(
        raise_error(
          ::RuntimeError,
          "reify can't be called without an object column"
        )
      )
    end
  end

  describe "where_object" do
    it "raises error" do
      n = NoObject.create!(letter: "A")
      expect {
        n.versions.where_object(foo: "bar")
      }.to(
        raise_error(
          ::RuntimeError,
          "where_object can't be called without an object column"
        )
      )
    end
  end
end
