require 'test_helper'

class CustomSerializer
  require 'json'
  def self.dump(object_hash)
    JSON.dump object_hash
  end

  def self.load(string)
    JSON.parse string
  end
end

class SerializerTest < ActiveSupport::TestCase

  context 'YAML Serializer' do
    setup do
      Fluxor.instance_eval <<-END
        has_paper_trail
      END

      @fluxor = Fluxor.create :name => 'Some text.'
      @fluxor.update_attributes :name => 'Some more text.'
    end

    should 'work with the default yaml serializer' do
      # Normal behaviour
      assert_equal 2, @fluxor.versions.length
      assert_nil @fluxor.versions[0].reify
      assert_equal 'Some text.', @fluxor.versions[1].reify.name


      # Check values are stored as YAML.
      hash = {"widget_id" => nil, "name" => "Some text.", "id" => 1}
      assert_equal YAML.dump(hash), @fluxor.versions[1].object
      assert_equal hash, YAML.load(@fluxor.versions[1].object)
    end
  end

  context 'Custom Serializer' do
    setup do
      PaperTrail.configure do |config|
        config.serializer = CustomSerializer
      end

      Fluxor.instance_eval <<-END
        has_paper_trail
      END

      @fluxor = Fluxor.create :name => 'Some text.'
      @fluxor.update_attributes :name => 'Some more text.'
    end

    teardown do
      PaperTrail.config.serializer = PaperTrail::Serializers::Yaml
    end

    should 'reify with custom serializer' do
      # Normal behaviour
      assert_equal 2, @fluxor.versions.length
      assert_nil @fluxor.versions[0].reify
      assert_equal 'Some text.', @fluxor.versions[1].reify.name

      # Check values are stored as JSON.
      hash = {"widget_id" => nil,"name" =>"Some text.","id" =>1}
      assert_equal JSON.dump(hash), @fluxor.versions[1].object
      assert_equal hash, JSON.parse(@fluxor.versions[1].object)
    end

    should 'store object_changes' do
      initial_changeset = {"name" => [nil, "Some text."], "id" => [nil, 1]}
      second_changeset =  {"name"=>["Some text.", "Some more text."]}
      assert_equal initial_changeset, @fluxor.versions[0].changeset
      assert_equal second_changeset,  @fluxor.versions[1].changeset
    end
  end

end
