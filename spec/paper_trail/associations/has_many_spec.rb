# frozen_string_literal: true

require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
  describe "customer, reified from version before order created" do
    it "has no orders" do
      customer = Customer.create(name: "customer_0")
      customer.update_attributes!(name: "customer_1")
      customer.orders.create!(order_date: Date.today)
      customer0 = customer.versions.last.reify(has_many: true)
      expect(customer0.orders).to(eq([]))
      expect(customer.orders.reload).not_to(eq([]))
    end
  end

  describe "customer, reified with mark_for_destruction, from version before order" do
    it "has orders, but they are marked for destruction" do
      customer = Customer.create(name: "customer_0")
      customer.update_attributes!(name: "customer_1")
      customer.orders.create!(order_date: Date.today)
      customer0 = customer.versions.last.reify(has_many: true, mark_for_destruction: true)
      expect(customer0.orders.map(&:marked_for_destruction?)).to(eq([true]))
    end
  end

  describe "customer, reified from version after order created" do
    it "has the expected order" do
      customer = Customer.create(name: "customer_0")
      customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      customer0 = customer.versions.last.reify(has_many: true)
      expect(customer0.orders.map(&:order_date)).to(eq(["order_date_0"]))
    end
  end

  describe "customer, reified from version after order line_items created" do
    it "has the expected line item" do
      customer = Customer.create(name: "customer_0")
      order = customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      order.line_items.create!(product: "product_0")
      customer0 = customer.versions.last.reify(has_many: true)
      expect(customer0.orders.first.line_items.map(&:product)).to(eq(["product_0"]))
    end
  end

  describe "customer, reified from version after order is updated" do
    it "has the updated order_date" do
      customer = Customer.create(name: "customer_0")
      order = customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      order.update_attributes(order_date: "order_date_1")
      order.update_attributes(order_date: "order_date_2")
      customer.update_attributes(name: "customer_2")
      order.update_attributes(order_date: "order_date_3")
      customer1 = customer.versions.last.reify(has_many: true)
      expect(customer1.orders.map(&:order_date)).to(eq(["order_date_2"]))
      expect(customer.orders.reload.map(&:order_date)).to(eq(["order_date_3"]))
    end
  end

  describe "customer, reified with has_many: false" do
    it "has the latest order from the database" do
      # TODO: This can be tested with fewer db records
      customer = Customer.create(name: "customer_0")
      order = customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      order.update_attributes(order_date: "order_date_1")
      order.update_attributes(order_date: "order_date_2")
      customer.update_attributes(name: "customer_2")
      order.update_attributes(order_date: "order_date_3")
      customer1 = customer.versions.last.reify(has_many: false)
      expect(customer1.orders.map(&:order_date)).to(eq(["order_date_3"]))
    end
  end

  describe "customer, reified from version before order is destroyed" do
    it "has the order" do
      # TODO: This can be tested with fewer db records
      customer = Customer.create(name: "customer_0")
      order = customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      order.update_attributes(order_date: "order_date_1")
      order.update_attributes(order_date: "order_date_2")
      customer.update_attributes(name: "customer_2")
      order.update_attributes(order_date: "order_date_3")
      order.destroy
      customer1 = customer.versions.last.reify(has_many: true)
      expect(customer1.orders.map(&:order_date)).to(eq(["order_date_2"]))
      expect(customer.orders.reload).to(eq([]))
    end
  end

  describe "customer, reified from version before order is destroyed" do
    it "has the order" do
      customer = Customer.create(name: "customer_0")
      order = customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      order.destroy
      customer1 = customer.versions.last.reify(has_many: true)
      expect(customer1.orders.map(&:order_date)).to(eq([order.order_date]))
      expect(customer.orders.reload).to(eq([]))
    end
  end

  describe "customer, reified from version after order is destroyed" do
    it "does not have the order" do
      customer = Customer.create(name: "customer_0")
      order = customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      order.destroy
      customer.update_attributes(name: "customer_2")
      customer1 = customer.versions.last.reify(has_many: true)
      expect(customer1.orders).to(eq([]))
    end
  end

  describe "customer, reified from version before order was updated" do
    it "has the old order_date" do
      customer = Customer.create(name: "customer_0")
      customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      customer.orders.create!(order_date: "order_date_1")
      customer0 = customer.versions.last.reify(has_many: true)
      expect(customer0.orders.map(&:order_date)).to(eq(["order_date_0"]))
      expect(
        customer.orders.reload.map(&:order_date)
      ).to match_array(%w[order_date_0 order_date_1])
    end
  end

  describe "customer, reified w/ mark_for_destruction, from version before 2nd order created" do
    it "has both orders, and the second is marked for destruction" do
      customer = Customer.create(name: "customer_0")
      customer.orders.create!(order_date: "order_date_0")
      customer.update_attributes(name: "customer_1")
      customer.orders.create!(order_date: "order_date_1")
      customer0 = customer.versions.last.reify(has_many: true, mark_for_destruction: true)
      order = customer0.orders.detect { |o| o.order_date == "order_date_1" }
      expect(order).to be_marked_for_destruction
    end
  end
end
