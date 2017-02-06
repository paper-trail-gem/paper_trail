require "test_helper"
require "custom_json_serializer"

class SerializerTest < ActiveSupport::TestCase
  context "YAML Serializer" do
    setup do
      @customer = Customer.create name: "Some text."

      # this is exactly what PaperTrail serializes
      @original_attributes = @customer.paper_trail.attributes_before_change

      @customer.update_attributes name: "Some more text."
    end

    should "work with the default `YAML` serializer" do
      # Normal behaviour
      assert_equal 2, @customer.versions.length
      assert_nil @customer.versions[0].reify
      assert_equal "Some text.", @customer.versions[1].reify.name

      # Check values are stored as `YAML`.
      assert_equal @original_attributes, YAML.load(@customer.versions[1].object)
      assert_equal YAML.dump(@original_attributes), @customer.versions[1].object
    end
  end

  context "JSON Serializer" do
    setup do
      PaperTrail.configure do |config|
        config.serializer = PaperTrail::Serializers::JSON
      end

      @customer = Customer.create name: "Some text."

      # this is exactly what PaperTrail serializes
      @original_attributes = @customer.paper_trail.attributes_before_change

      @customer.update_attributes name: "Some more text."
    end

    teardown do
      PaperTrail.config.serializer = PaperTrail::Serializers::YAML
    end

    should "reify with JSON serializer" do
      # Normal behaviour
      assert_equal 2, @customer.versions.length
      assert_nil @customer.versions[0].reify
      assert_equal "Some text.", @customer.versions[1].reify.name

      # Check values are stored as JSON.
      assert_equal @original_attributes,
        ActiveSupport::JSON.decode(@customer.versions[1].object)
      assert_equal ActiveSupport::JSON.encode(@original_attributes),
        @customer.versions[1].object
    end

    should "store object_changes" do
      initial_changeset = { "name" => [nil, "Some text."], "id" => [nil, @customer.id] }
      second_changeset = { "name" => ["Some text.", "Some more text."] }
      assert_equal initial_changeset, @customer.versions[0].changeset
      assert_equal second_changeset,  @customer.versions[1].changeset
    end
  end

  context "Custom Serializer" do
    setup do
      PaperTrail.configure do |config|
        config.serializer = CustomJsonSerializer
      end

      @customer = Customer.create

      # this is exactly what PaperTrail serializes
      @original_attributes = @customer.
        paper_trail.
        attributes_before_change.
        reject { |_k, v| v.nil? }

      @customer.update_attributes name: "Some more text."
    end

    teardown do
      PaperTrail.config.serializer = PaperTrail::Serializers::YAML
    end

    should "reify with custom serializer" do
      # Normal behaviour
      assert_equal 2, @customer.versions.length
      assert_nil @customer.versions[0].reify
      assert_nil @customer.versions[1].reify.name

      # Check values are stored as JSON.
      assert_equal @original_attributes,
        ActiveSupport::JSON.decode(@customer.versions[1].object)
      assert_equal ActiveSupport::JSON.encode(@original_attributes),
        @customer.versions[1].object
    end

    should "store object_changes" do
      initial_changeset = { "id" => [nil, @customer.id] }
      second_changeset = { "name" => [nil, "Some more text."] }
      assert_equal initial_changeset, @customer.versions[0].changeset
      assert_equal second_changeset,  @customer.versions[1].changeset
    end
  end
end
