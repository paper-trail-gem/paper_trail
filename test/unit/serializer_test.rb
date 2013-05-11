require 'test_helper'
require 'custom_json_serializer'

class SerializerTest < ActiveSupport::TestCase

  context 'YAML Serializer' do
    setup do
      Fluxor.instance_eval <<-END
        has_paper_trail
      END

      @fluxor = Fluxor.create :name => 'Some text.'
      @original_fluxor_attributes = @fluxor.send(:item_before_change).attributes # this is exactly what PaperTrail serializes
      @fluxor.update_attributes :name => 'Some more text.'
    end

    should 'work with the default yaml serializer' do
      # Normal behaviour
      assert_equal 2, @fluxor.versions.length
      assert_nil @fluxor.versions[0].reify
      assert_equal 'Some text.', @fluxor.versions[1].reify.name

      # Check values are stored as YAML.
      assert_equal @original_fluxor_attributes, YAML.load(@fluxor.versions[1].object)
      # This test can't consistently pass in Ruby1.8 because hashes do no preserve order, which means the order of the
      # attributes in the YAML can't be ensured.
      if RUBY_VERSION.to_f >= 1.9
        assert_equal YAML.dump(@original_fluxor_attributes), @fluxor.versions[1].object
      end
    end
  end

  context 'JSON Serializer' do
    setup do
      PaperTrail.configure do |config|
        config.serializer = PaperTrail::Serializers::Json
      end

      Fluxor.instance_eval <<-END
        has_paper_trail
      END

      @fluxor = Fluxor.create :name => 'Some text.'
      @original_fluxor_attributes = @fluxor.send(:item_before_change).attributes # this is exactly what PaperTrail serializes
      @fluxor.update_attributes :name => 'Some more text.'
    end

    teardown do
      PaperTrail.config.serializer = PaperTrail::Serializers::Yaml
    end

    should 'reify with JSON serializer' do
      # Normal behaviour
      assert_equal 2, @fluxor.versions.length
      assert_nil @fluxor.versions[0].reify
      assert_equal 'Some text.', @fluxor.versions[1].reify.name

      # Check values are stored as JSON.
      assert_equal @original_fluxor_attributes, ActiveSupport::JSON.decode(@fluxor.versions[1].object)
      # This test can't consistently pass in Ruby1.8 because hashes do no preserve order, which means the order of the
      # attributes in the JSON can't be ensured.
      if RUBY_VERSION.to_f >= 1.9
        assert_equal ActiveSupport::JSON.encode(@original_fluxor_attributes), @fluxor.versions[1].object
      end
    end

    should 'store object_changes' do
      initial_changeset = {"name" => [nil, "Some text."], "id" => [nil, 1]}
      second_changeset =  {"name"=>["Some text.", "Some more text."]}
      assert_equal initial_changeset, @fluxor.versions[0].changeset
      assert_equal second_changeset,  @fluxor.versions[1].changeset
    end
  end

  context 'Custom Serializer' do
    setup do
      PaperTrail.configure do |config|
        config.serializer = CustomJsonSerializer
      end

      Fluxor.instance_eval <<-END
        has_paper_trail
      END

      @fluxor = Fluxor.create
      @original_fluxor_attributes = @fluxor.send(:item_before_change).attributes.reject { |k,v| v.nil? } # this is exactly what PaperTrail serializes
      @fluxor.update_attributes :name => 'Some more text.'
    end

    teardown do
      PaperTrail.config.serializer = PaperTrail::Serializers::Yaml
    end

    should 'reify with custom serializer' do
      # Normal behaviour
      assert_equal 2, @fluxor.versions.length
      assert_nil @fluxor.versions[0].reify
      assert_nil @fluxor.versions[1].reify.name

      # Check values are stored as JSON.
      assert_equal @original_fluxor_attributes, ActiveSupport::JSON.decode(@fluxor.versions[1].object)
      # This test can't consistently pass in Ruby1.8 because hashes do no preserve order, which means the order of the
      # attributes in the JSON can't be ensured.
      if RUBY_VERSION.to_f >= 1.9
        assert_equal ActiveSupport::JSON.encode(@original_fluxor_attributes), @fluxor.versions[1].object
      end
    end

    should 'store object_changes' do
      initial_changeset = {"id" => [nil, 1]}
      second_changeset =  {"name"=>[nil, "Some more text."]}
      assert_equal initial_changeset, @fluxor.versions[0].changeset
      assert_equal second_changeset,  @fluxor.versions[1].changeset
    end
  end

end
