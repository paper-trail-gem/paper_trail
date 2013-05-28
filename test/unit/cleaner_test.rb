require 'test_helper'

class PaperTrailCleanerTest < ActiveSupport::TestCase

  test 'Baseline' do
    @animal = Animal.create :name => 'Animal'
    @animal.update_attributes :name => 'Animal from the Muppets'
    @animal.update_attributes :name => 'Animal Muppet'

    @dog = Dog.create :name => 'Snoopy'
    @dog.update_attributes :name => 'Scooby'
    @dog.update_attributes :name => 'Scooby Doo'

    @cat = Cat.create :name => 'Garfield'
    @cat.update_attributes :name => 'Garfield (I hate Mondays)'
    @cat.update_attributes :name => 'Garfield The Cat'
    assert_equal 9, Version.count
  end

  test 'cleaner removes extra versions' do
    @animal = Animal.create :name => 'Animal'
    @animal.update_attributes :name => 'Animal from the Muppets'
    @animal.update_attributes :name => 'Animal Muppet'
    PaperTrail.clean_paper_trail_versions
    assert_equal 1, Version.all.count
  end

  test 'cleaner removes versions' do
    @animal = Animal.create :name => 'Animal'
    @animal.update_attributes :name => 'Animal from the Muppets'
    @animal.update_attributes :name => 'Animal Muppet'

    @dog = Dog.create :name => 'Snoopy'
    @dog.update_attributes :name => 'Scooby'
    @dog.update_attributes :name => 'Scooby Doo'

    @cat = Cat.create :name => 'Garfield'
    @cat.update_attributes :name => 'Garfield (I hate Mondays)'
    @cat.update_attributes :name => 'Garfield The Cat'
    PaperTrail.clean_paper_trail_versions
    assert_equal 3, Version.all.count
  end

  test 'cleaner keeps the correct (last) version' do
    @animal = Animal.create :name => 'Animal'
    @animal.update_attributes :name => 'Animal from the Muppets'
    @animal.update_attributes :name => 'Animal Muppet'
    PaperTrail.clean_paper_trail_versions
    assert_equal 1, Version.all.count
    assert_equal "Animal Muppet", @animal.name
  end
end
