# frozen_string_literal: true

require "spec_helper"

# The `Post` model uses a custom version class, `PostVersion`
RSpec.describe Post, type: :model, versioning: true do
  it "inserts records into the correct table, post_versions" do
    post = Post.create
    expect(PostVersion.count).to(eq(1))
    post.update_attributes(content: "Some new content")
    expect(PostVersion.count).to(eq(2))
    expect(PaperTrail::Version.count).to(eq(0))
  end

  context "on the first version" do
    it "have the correct index" do
      post = Post.create
      version = post.versions.first
      expect(version.index).to(eq(0))
    end
  end

  it "have versions of the custom class" do
    post = Post.create
    expect(post.versions.first.class.name).to(eq("PostVersion"))
  end

  describe "#changeset" do
    it "returns nil because the object_changes column doesn't exist" do
      post = Post.create
      post.update_attributes(content: "Some new content")
      expect(post.versions.last.changeset).to(be_nil)
    end
  end
end
