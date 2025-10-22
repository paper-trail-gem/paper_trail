# frozen_string_literal: true

require "spec_helper"

RSpec.describe Car do
  it { is_expected.to be_versioned }

  describe "changeset", :versioning do
    it "has the expected keys (see issue 738)" do
      car = described_class.create!(name: "Alice")
      car.update(name: "Bob")
      expect(car.versions.last.changeset.keys).to include("name")
    end
  end

  describe "attributes and accessors", :versioning do
    it "reifies attributes that are not AR attributes" do
      car = described_class.create name: "Pinto", color: "green"
      car.update color: "yellow"
      car.update color: "brown"
      expect(car.versions.second.reify.color).to eq("yellow")
    end

    it "reifies attributes that once were attributes but now just attr_accessor" do
      car = described_class.create name: "Pinto", color: "green"
      car.update color: "yellow"
      changes = PaperTrail::Serializers::YAML.load(car.versions.last.attributes["object"])
      changes[:top_speed] = 80
      car.versions.first.update object: changes.to_yaml
      car.reload
      expect(car.versions.first.reify.top_speed).to eq(80)
    end
  end
end
