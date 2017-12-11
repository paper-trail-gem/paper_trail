# frozen_string_literal: true

require "spec_helper"
require "support/custom_json_serializer"

RSpec.describe(PaperTrail, versioning: true) do
  context "YAML serializer" do
    it "saves the expected YAML in the object column" do
      customer = Customer.create(name: "Some text.")
      original_attributes = customer.paper_trail.attributes_before_change
      customer.update(name: "Some more text.")
      expect(customer.versions.length).to(eq(2))
      expect(customer.versions[0].reify).to(be_nil)
      expect(customer.versions[1].reify.name).to(eq("Some text."))
      expect(YAML.load(customer.versions[1].object)).to(eq(original_attributes))
      expect(customer.versions[1].object).to(eq(YAML.dump(original_attributes)))
    end
  end

  context "JSON Serializer" do
    before do
      PaperTrail.configure do |config|
        config.serializer = PaperTrail::Serializers::JSON
      end
    end

    after do
      PaperTrail.config.serializer = PaperTrail::Serializers::YAML
    end

    it "reify with JSON serializer" do
      customer = Customer.create(name: "Some text.")
      original_attributes = customer.paper_trail.attributes_before_change
      customer.update(name: "Some more text.")
      expect(customer.versions.length).to(eq(2))
      expect(customer.versions[0].reify).to(be_nil)
      expect(customer.versions[1].reify.name).to(eq("Some text."))
      expect(ActiveSupport::JSON.decode(customer.versions[1].object)).to(eq(original_attributes))
      expect(customer.versions[1].object).to(eq(ActiveSupport::JSON.encode(original_attributes)))
    end

    describe "#changeset" do
      it "returns the expected hash" do
        customer = Customer.create(name: "Some text.")
        customer.update(name: "Some more text.")
        initial_changeset = { "name" => [nil, "Some text."], "id" => [nil, customer.id] }
        second_changeset = { "name" => ["Some text.", "Some more text."] }
        expect(customer.versions[0].changeset).to(eq(initial_changeset))
        expect(customer.versions[1].changeset).to(eq(second_changeset))
      end
    end
  end

  context "Custom Serializer" do
    before do
      PaperTrail.configure { |config| config.serializer = CustomJsonSerializer }
    end

    after do
      PaperTrail.config.serializer = PaperTrail::Serializers::YAML
    end

    it "reify with custom serializer" do
      customer = Customer.create
      original_attributes = customer.paper_trail.attributes_before_change.reject { |_k, v| v.nil? }
      customer.update(name: "Some more text.")
      expect(customer.versions.length).to(eq(2))
      expect(customer.versions[0].reify).to(be_nil)
      expect(customer.versions[1].reify.name).to(be_nil)
      expect(
        ActiveSupport::JSON.decode(customer.versions[1].object)
      ).to eq(original_attributes)
      expect(
        customer.versions[1].object
      ).to eq(ActiveSupport::JSON.encode(original_attributes))
    end

    describe "#changeset" do
      it "store object_changes" do
        customer = Customer.create
        customer.update(name: "banana")
        expect(customer.versions[0].changeset).to eq("id" => [nil, customer.id])
        expect(customer.versions[1].changeset).to eq("name" => [nil, "banana"])
      end
    end
  end
end
