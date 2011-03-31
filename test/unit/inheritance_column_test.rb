require 'test_helper'

class InheritanceColumnTest < ActiveSupport::TestCase

  context 'STI models' do
    setup do
      @animal = Animal.create :name => 'Animal'
      @animal.update_attributes :name => 'Animal from the Muppets'
      @animal.update_attributes :name => 'Animal Muppet'

      @dog = Dog.create :name => 'Snoopy'
      @dog.update_attributes :name => 'Scooby'
      @dog.update_attributes :name => 'Scooby Doo'

      @cat = Cat.create :name => 'Garfield'
      @cat.update_attributes :name => 'Garfield (I hate Mondays)'
      @cat.update_attributes :name => 'Garfield The Cat'
    end

    should 'work with custom STI inheritance column' do
      assert_equal 9, Version.count
      assert_equal 3, @animal.versions.count
      assert_equal 3, @dog.versions.count
      assert_equal 3, @cat.versions.count

      assert_equal 'Animal from the Muppets',   @animal.versions.last.reify.name
      assert_equal 'Scooby',       @dog.versions.last.reify.name
      assert_equal 'Garfield (I hate Mondays)', @cat.versions.last.reify.name
    end
  end

end
