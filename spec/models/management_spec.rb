# frozen_string_literal: true

require "spec_helper"

::RSpec.describe(::Management, type: :model, versioning: true) do
  it "utilises the base_class for STI classes having no type column" do
    expect(Management.inheritance_column).to eq("type")
    expect(Management.columns.map(&:name)).not_to include("type")

    # Create, update, and destroy a Management and a Customer
    customer1 = Customer.create(name: "Cust 1")
    customer2 = Management.create(name: "Cust 2")
    customer1.update(name: "Cust 1a")
    customer2.update(name: "Cust 2a")
    customer1.destroy
    customer2.destroy

    # All versions end up with an `item_type` of Customer
    expect(
      PaperTrail::Version.where(item_type: "Customer").count
    ).to eq(6)
    expect(
      PaperTrail::Version.where(item_type: "Management").count
    ).to eq(0)

    # The item_subtype, on the other hand, is 3 and 3
    expect(
      PaperTrail::Version.where(item_subtype: "Customer").count
    ).to eq(3)
    expect(
      PaperTrail::Version.where(item_subtype: "Management").count
    ).to eq(3)
  end
end
