# frozen_string_literal: true

require "spec_helper"

RSpec.describe CarWithLockVersion do
  it { is_expected.to be_versioned }

  describe "reify options", :versioning do
    it "increments lock_version if present" do
      car = described_class.create!(name: "Pinto", color: "green")
      car.update!(color: "yellow")
      version = car.versions.last
      reified = version.reify
      current_lock_version = car.lock_version
      expect(reified.lock_version).to eq(current_lock_version + 1)
    end
  end
end
