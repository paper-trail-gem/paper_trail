# frozen_string_literal: true

require "spec_helper"

RSpec.describe Translation, type: :model, versioning: true do
  context "for non-US translations" do
    it "not change the number of versions" do
      described_class.create!(headline: "Headline")
      expect(PaperTrail::Version.count).to(eq(0))
    end

    context "after update" do
      it "not change the number of versions" do
        translation = described_class.create!(headline: "Headline")
        translation.update(content: "Content")
        expect(PaperTrail::Version.count).to(eq(0))
      end
    end

    context "after destroy" do
      it "not change the number of versions" do
        translation = described_class.create!(headline: "Headline")
        translation.destroy
        expect(PaperTrail::Version.count).to(eq(0))
      end
    end
  end

  context "for US translations" do
    context "that are drafts" do
      it "creation does not change the number of versions" do
        translation = described_class.new(headline: "Headline")
        translation.language_code = "US"
        translation.type = "DRAFT"
        translation.save!
        expect(PaperTrail::Version.count).to(eq(0))
      end

      it "update does not change the number of versions" do
        translation = described_class.new(headline: "Headline")
        translation.language_code = "US"
        translation.type = "DRAFT"
        translation.save!
        translation.update(content: "Content")
        expect(PaperTrail::Version.count).to(eq(0))
      end
    end

    context "that are not drafts" do
      it "create changes the number of versions" do
        described_class.create!(headline: "Headline", language_code: "US")
        expect(PaperTrail::Version.count).to(eq(1))
      end

      it "update does not change the number of versions" do
        translation = described_class.create!(headline: "Headline", language_code: "US")
        translation.update(content: "Content")
        expect(PaperTrail::Version.count).to(eq(2))
        expect(translation.versions.size).to(eq(2))
      end

      it "destroy does not change the number of versions" do
        translation = described_class.new(headline: "Headline")
        translation.language_code = "US"
        translation.save!
        translation.destroy
        expect(PaperTrail::Version.count).to(eq(2))
        expect(translation.versions.size).to(eq(2))
      end
    end
  end
end
