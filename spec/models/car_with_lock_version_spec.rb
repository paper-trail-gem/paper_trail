# frozen_string_literal: true

require "spec_helper"

RSpec.describe CarWithLockVersion do
  it { is_expected.to be_versioned }

  describe "reify options", :versioning do
    it "increments lock_version if present" do
      car = described_class.create!(name: "Pinto", color: "green", lock_version: 1)
      car.update!(color: "yellow")
      reified = car.versions.last.reify
      expect(reified.lock_version).to eq(2)
    end
  end
end
