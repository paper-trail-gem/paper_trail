# frozen_string_literal: true

require "spec_helper"

RSpec.describe Plant, :versioning do
  it "baseline test setup" do
    expect(described_class.new).to be_versioned
    expect(described_class.inheritance_column).to eq("species")
  end

  describe "#descends_from_active_record?" do
    it "returns true, meaning that Animal is not an STI subclass" do
      expect(described_class.descends_from_active_record?).to eq(true)
    end
  end

  it "works with non standard STI column contents" do
    plant = described_class.create
    plant.destroy

    tomato = Tomato.create
    tomato.destroy

    reified = plant.versions.last.reify
    expect(reified.class).to eq(described_class)

    reified = tomato.versions.last.reify
    expect(reified.class).to eq(Tomato)
  end
end
