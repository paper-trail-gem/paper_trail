# frozen_string_literal: true

require "spec_helper"

RSpec.describe Article, versioning: true do
  describe ".create" do
    it "also creates a version record" do
      expect { described_class.create }.to(
        change(PaperTrail::Version, :count).by(+1)
      )
    end
  end

  context "when updating an ignored column" do
    it "not change the number of versions" do
      article = described_class.create
      article.update(title: "My first title")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "when updating an ignored column with truly Proc" do
    it "not change the number of versions" do
      article = described_class.create
      article.update(abstract: "ignore abstract")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "when updating an ignored column with falsy Proc" do
    it "change the number of versions" do
      article = described_class.create
      article.update(abstract: "do not ignore abstract!")
      expect(PaperTrail::Version.count).to(eq(2))
    end
  end

  context "when updating an ignored column, ignored with truly Proc and a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update(
        title: "My first title",
        content: "Some text here.",
        abstract: "ignore abstract"
      )
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
    end

    it "have stored only non-ignored attributes" do
      article = described_class.create
      article.update(
        title: "My first title",
        content: "Some text here.",
        abstract: "ignore abstract"
      )
      expected = { "content" => [nil, "Some text here."] }
      expect(article.versions.last.changeset).to(eq(expected))
    end
  end

  context "when updating an ignored column, ignored with falsy Proc and a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update(
        title: "My first title",
        content: "Some text here.",
        abstract: "do not ignore abstract"
      )
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
    end

    it "stores only non-ignored attributes" do
      article = described_class.create
      article.update(
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

  context "when updating a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update(content: "Some text here.")
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
    end
  end

  context "when updating a non-ignored and non-selected column" do
    it "not change the number of versions" do
      article = described_class.create
      article.update(abstract: "Other abstract")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "when updating a skipped column" do
    it "not change the number of versions" do
      article = described_class.create
      article.update(file_upload: "Your data goes here")
      expect(PaperTrail::Version.count).to(eq(1))
    end
  end

  context "when updating a skipped column and a selected column" do
    it "change the number of versions" do
      article = described_class.create
      article.update(
        file_upload: "Your data goes here",
        content: "Some text here."
      )
      expect(PaperTrail::Version.count).to(eq(2))
    end

    it "show the new version in the model's `versions` association" do
      article = described_class.create
      article.update(
        file_upload: "Your data goes here",
        content: "Some text here."
      )
      expect(article.versions.size).to(eq(2))
    end

    it "have stored only non-skipped attributes" do
      article = described_class.create
      article.update(
        file_upload: "Your data goes here",
        content: "Some text here."
      )
      expect(
        article.versions.last.changeset
      ).to(eq("content" => [nil, "Some text here."]))
    end

    context "when updated again" do
      it "have removed the skipped attributes when saving the previous version" do
        article = described_class.create
        article.update(
          file_upload: "Your data goes here",
          content: "Some text here."
        )
        article.update(
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
        article.update(
          file_upload: "Your data goes here",
          content: "Some text here."
        )
        article.update(
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

  describe "#destroy" do
    it "creates a version record" do
      article = described_class.create
      article.destroy
      expect(PaperTrail::Version.count).to(eq(2))
      expect(article.versions.size).to(eq(2))
      expect(article.versions.map(&:event)).to(match_array(%w[create destroy]))
    end
  end

  context "with an item" do
    let(:article) { described_class.new(title: initial_title) }
    let(:initial_title) { "Foobar" }

    context "when it is created" do
      before { article.save }

      it "store fixed meta data" do
        expect(article.versions.last.answer).to(eq(42))
      end

      it "store dynamic meta data which is independent of the item" do
        expect(article.versions.last.question).to(eq("31 + 11 = 42"))
      end

      it "store dynamic meta data which depends on the item" do
        expect(article.versions.last.article_id).to(eq(article.id))
      end

      it "store dynamic meta data based on a method of the item" do
        expect(article.versions.last.action).to(eq(article.action_data_provider_method))
      end

      it "store dynamic meta data based on an attribute of the item at creation" do
        expect(article.versions.last.title).to(eq(initial_title))
      end
    end

    context "when it is created, then updated" do
      before do
        article.save
        article.update!(content: "Better text.", title: "Rhubarb")
      end

      it "store fixed meta data" do
        expect(article.versions.last.answer).to(eq(42))
      end

      it "store dynamic meta data which is independent of the item" do
        expect(article.versions.last.question).to(eq("31 + 11 = 42"))
      end

      it "store dynamic meta data which depends on the item" do
        expect(article.versions.last.article_id).to(eq(article.id))
      end

      it "store dynamic meta data based on an attribute of the item prior to the update" do
        expect(article.versions.last.title).to(eq(initial_title))
      end
    end

    context "when it is created, then destroyed" do
      before do
        article.save
        article.destroy
      end

      it "store fixed metadata" do
        expect(article.versions.last.answer).to(eq(42))
      end

      it "store dynamic metadata which is independent of the item" do
        expect(article.versions.last.question).to(eq("31 + 11 = 42"))
      end

      it "store dynamic metadata which depends on the item" do
        expect(article.versions.last.article_id).to(eq(article.id))
      end

      it "store dynamic metadata based on attribute of item prior to destruction" do
        expect(article.versions.last.title).to(eq(initial_title))
      end
    end
  end
end
