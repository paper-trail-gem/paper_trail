# frozen_string_literal: true

require "spec_helper"

RSpec.describe Book, versioning: true do
  context "with :has_many :through" do
    it "store version on source <<" do
      book = described_class.create(title: "War and Peace")
      dostoyevsky = Person.create(name: "Dostoyevsky")
      Person.create(name: "Solzhenitsyn")
      count = PaperTrail::Version.count
      (book.authors << dostoyevsky)
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(book.authorships.first.versions.first).to(eq(PaperTrail::Version.last))
    end

    it "store version on source create" do
      book = described_class.create(title: "War and Peace")
      Person.create(name: "Dostoyevsky")
      Person.create(name: "Solzhenitsyn")
      count = PaperTrail::Version.count
      book.authors.create(name: "Tolstoy")
      expect((PaperTrail::Version.count - count)).to(eq(2))
      expect(
        [PaperTrail::Version.order(:id).to_a[-2].item, PaperTrail::Version.last.item]
      ).to contain_exactly(Person.last, Authorship.last)
    end

    it "store version on join destroy" do
      book = described_class.create(title: "War and Peace")
      dostoyevsky = Person.create(name: "Dostoyevsky")
      Person.create(name: "Solzhenitsyn")
      (book.authors << dostoyevsky)
      count = PaperTrail::Version.count
      book.authorships.reload.last.destroy
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(PaperTrail::Version.last.reify.book).to(eq(book))
      expect(PaperTrail::Version.last.reify.author).to(eq(dostoyevsky))
    end

    it "store version on join clear" do
      book = described_class.create(title: "War and Peace")
      dostoyevsky = Person.create(name: "Dostoyevsky")
      Person.create(name: "Solzhenitsyn")
      book.authors << dostoyevsky
      count = PaperTrail::Version.count
      book.authorships.reload.destroy_all
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(PaperTrail::Version.last.reify.book).to(eq(book))
      expect(PaperTrail::Version.last.reify.author).to(eq(dostoyevsky))
    end
  end

  context "when a persisted record is updated then destroyed" do
    it "has changes" do
      book = described_class.create! title: "A"
      changes = YAML.load book.versions.last.attributes["object_changes"]
      expect(changes).to eq("id" => [nil, book.id], "title" => [nil, "A"])

      book.update! title: "B"
      changes = YAML.load book.versions.last.attributes["object_changes"]
      expect(changes).to eq("title" => %w[A B])

      book.destroy
      changes = YAML.load book.versions.last.attributes["object_changes"]
      expect(changes).to eq("id" => [book.id, nil], "title" => ["B", nil])
    end
  end
end
