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

  context "when option: association_touch_versions is set false" do
    around do |example|
      PaperTrail.config.association_touch_versions = false
      example.run
      PaperTrail.config.association_touch_versions = true
    end

    it "does not create a version record for association" do
      customer = Customer.create!
      order = described_class.create!(customer_id: customer.id)
      order.reload.update(order_date: Time.now.getlocal)

      expect(customer.versions.count).to(eq(1))
    end
  end
end
