# frozen_string_literal: true

require "spec_helper"

# The `Post` model uses a custom version class, `PostVersion`
RSpec.describe Post, versioning: true do
  it "inserts records into the correct table, post_versions" do
    post = described_class.create
    expect(PostVersion.count).to(eq(1))
    post.update(content: "Some new content")
    expect(PostVersion.count).to(eq(2))
    expect(PaperTrail::Version.count).to(eq(0))
  end

  context "with the first version" do
    it "have the correct index" do
      post = described_class.create
      version = post.versions.first
      expect(version.index).to(eq(0))
    end
  end

  it "have versions of the custom class" do
    post = described_class.create
    expect(post.versions.first.class.name).to(eq("PostVersion"))
  end

  describe "#changeset" do
    it "returns nil because the object_changes column doesn't exist" do
      post = described_class.create
      post.update(content: "Some new content")
      expect(post.versions.last.changeset).to(be_nil)
    end
  end
end
