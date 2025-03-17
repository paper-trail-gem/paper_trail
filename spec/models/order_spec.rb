# frozen_string_literal: true

require "spec_helper"

RSpec.describe Order, :versioning do
  context "when the record destroyed" do
    it "creates a version record for association" do
      customer = Customer.create!
      described_class.create!(customer: customer)
      described_class.destroy_all

      expect(customer.versions.count).to(eq(3))
    end

    # We need to use an instance variable to work with the `n_plus_one_control` gem in this spec.
    # rubocop:disable RSpec/InstanceVariable
    context "when the record has many associated records (N+1 check)", :n_plus_one do
      populate do |n|
        @customer = Customer.create!

        n.times do
          @customer.orders.create!
        end
      end

      it "does not cause an N+1 query" do
        expect { @customer.destroy! }.to perform_constant_number_of_queries
      end
    end
    # rubocop:enable RSpec/InstanceVariable
  end
end
