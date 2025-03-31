# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cat, type: :model, versioning: true do
  describe "#descends_from_active_record?" do
    it "returns false, meaning that Cat is an STI subclass" do
      expect(described_class.descends_from_active_record?).to eq(false)
    end
  end
end
