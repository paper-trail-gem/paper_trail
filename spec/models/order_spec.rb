# frozen_string_literal: true

require "spec_helper"

RSpec.describe Order, type: :model, versioning: true do
  context "when the record destroyed" do
    it "creates a version record for association" do
      customer = Customer.create!
      described_class.create!(customer: customer)
      described_class.destroy_all

      expect(customer.versions.count).to(eq(3))
    end
  end
end
