# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cat, type: :model, versioning: true do
  describe "#descends_from_active_record?" do
    it "returns false, meaning that Cat is an STI subclass" do
      expect(described_class.descends_from_active_record?).to eq(false)
    end
  end

  describe "#paper_trail" do
    before do
      ::PaperTrail.config.i_have_updated_my_existing_item_types = nil
    end

    after do
      ::PaperTrail.config.i_have_updated_my_existing_item_types = true
    end

    it "warns that STI item_type has not been updated" do
      expect { described_class.create }.to(
        output(
          /It looks like Cat is an STI subclass, and you have not yet updated/
        ).to_stderr
      )
    end
  end
end
