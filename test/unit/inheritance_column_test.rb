require 'test_helper'

class InheritanceColumnTest < ActiveSupport::TestCase

  context 'STI models' do
    setup do
      @animal = Animal.create :name => 'Animal'
      @animal.update_attributes :name => 'Animal from the Muppets'
      @animal.update_attributes :name => 'Animal Muppet'
      @animal.destroy

      @dog = Dog.create :name => 'Snoopy'
      @dog.update_attributes :name => 'Scooby'
      @dog.update_attributes :name => 'Scooby Doo'
      @dog.destroy

      @cat = Cat.create :name => 'Garfield'
      @cat.update_attributes :name => 'Garfield (I hate Mondays)'
      @cat.update_attributes :name => 'Garfield The Cat'
      @cat.destroy
    end

    should 'work with custom STI inheritance column' do
      assert_equal 12, Version.count
      assert_equal 4, @animal.versions.count
      assert @animal.versions.first.reify.nil?
      @animal.versions[1..-1].each { |v| assert_equal 'Animal', v.reify.class.name }

      # For some reason `@dog.versions` doesn't include the final `destroy` version.
      # Neither do `@dog.versions.scoped` nor `@dog.versions(true)` nor `@dog.versions.reload`.
      dog_versions = Version.where(:item_id => @dog.id)
      assert_equal 4, dog_versions.count
      assert dog_versions.first.reify.nil?
      dog_versions[1..-1].each { |v| assert_equal 'Dog', v.reify.class.name }

      cat_versions = Version.where(:item_id => @cat.id)
      assert_equal 4, cat_versions.count
      assert cat_versions.first.reify.nil?
      cat_versions[1..-1].each { |v| assert_equal 'Cat', v.reify.class.name }
    end
  end

end
