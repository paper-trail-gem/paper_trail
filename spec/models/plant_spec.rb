# frozen_string_literal: true

require "spec_helper"

RSpec.describe Plant, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Plant.new).to be_versioned
    expect(Plant.inheritance_column).to eq("species")
  end

  describe "#descends_from_active_record?" do
    it "returns true, meaning that Animal is not an STI subclass" do
      expect(described_class.descends_from_active_record?).to eq(true)
    end
  end

  it "works with non standard STI column contents" do
    plant = Plant.create
    plant.destroy

    tomato = Tomato.create
    tomato.destroy

    reified = plant.versions.last.reify
    expect(reified.class).to eq(Plant)

    reified = tomato.versions.last.reify
    expect(reified.class).to eq(Tomato)
  end
end
