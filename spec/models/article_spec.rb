# frozen_string_literal: true

require "spec_helper"

RSpec.describe Article, type: :model, versioning: true do
  describe ".create" do
    it "also creates a version record" do
      expect { described_class.create }.to(
        change { PaperTrail::Version.count }.by(+1)
      )
    end
  end

  context "which updates an ignored column" do
    it "not change the number of versions" do
      article = described_class.create
      article.update_attributes(title: "My first title")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "which updates an ignored column with truly Proc" do
    it "not change the number of versions" do
      article = described_class.create
      article.update_attributes(abstract: "ignore abstract")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "which updates an ignored column with falsy Proc" do
    it "change the number of versions" do
      article = described_class.create
      article.update_attributes(abstract: "do not ignore abstract!")
      expect(PaperTrail::Version.count).to(eq(2))
    end
  end

  context "which updates an ignored column, ignored with truly Proc and a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update_attributes(
        title: "My first title",
        content: "Some text here.",
        abstract: "ignore abstract"
      )
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
    end

    it "have stored only non-ignored attributes" do
      article = described_class.create
      article.update_attributes(
        title: "My first title",
        content: "Some text here.",
        abstract: "ignore abstract"
      )
      expected = { "content" => [nil, "Some text here."] }
      expect(article.versions.last.changeset).to(eq(expected))
    end
  end

  context "which updates an ignored column, ignored with falsy Proc and a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update_attributes(
        title: "My first title",
        content: "Some text here.",
        abstract: "do not ignore abstract"
      )
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
    end

    it "stores only non-ignored attributes" do
      article = described_class.create
      article.update_attributes(
        title: "My first title",
        content: "Some text here.",
        abstract: "do not ignore abstract"
      )
      expected = {
        "content" => [nil, "Some text here."],
        "abstract" => [nil, "do not ignore abstract"]
      }
      expect(article.versions.last.changeset).to(eq(expected))
    end
  end

  context "which updates a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update_attributes(content: "Some text here.")
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
    end
  end

  context "which updates a non-ignored and non-selected column" do
    it "not change the number of versions" do
      article = described_class.create
      article.update_attributes(abstract: "Other abstract")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "which updates a skipped column" do
    it "not change the number of versions" do
      article = described_class.create
      article.update_attributes(file_upload: "Your data goes here")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "which updates a skipped column and a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update_attributes(
        file_upload: "Your data goes here",
        content: "Some text here."
      )
      expect(PaperTrail::Version.count).to(eq(2))
    end

    it "show the new version in the model's `versions` association" do
      article = described_class.create
      article.update_attributes(
        file_upload: "Your data goes here",
        content: "Some text here."
      )
      expect(article.versions.size).to(eq(2))
    end

    it "have stored only non-skipped attributes" do
      article = described_class.create
      article.update_attributes(
        file_upload: "Your data goes here",
        content: "Some text here."
      )
      expect(
        article.versions.last.changeset
      ).to(eq("content" => [nil, "Some text here."]))
    end

    context "and when updated again" do
      it "have removed the skipped attributes when saving the previous version" do
        article = described_class.create
        article.update_attributes(
          file_upload: "Your data goes here",
          content: "Some text here."
        )
        article.update_attributes(
          file_upload: "More data goes here",
          content: "More text here."
        )
        old_article = article.versions.last
        expect(
          PaperTrail.serializer.load(old_article.object)["file_upload"]
        ).to(be_nil)
      end

      it "have kept the non-skipped attributes in the previous version" do
        article = described_class.create
        article.update_attributes(
          file_upload: "Your data goes here",
          content: "Some text here."
        )
        article.update_attributes(
          file_upload: "More data goes here",
          content: "More text here."
        )
        old_article = article.versions.last
        expect(
          PaperTrail.serializer.load(old_article.object)["content"]
        ).to(eq("Some text here."))
      end
    end
  end

  context "#destroy" do
    it "creates a version record" do
      article = described_class.create
      article.destroy
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
      expect(article.versions.map(&:event)).to(match_array(%w[create destroy]))
    end
  end
end
