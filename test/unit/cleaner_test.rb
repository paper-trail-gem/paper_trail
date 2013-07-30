require 'test_helper'

class PaperTrailCleanerTest < ActiveSupport::TestCase

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
    @animals = [@animal, @dog, @cat]
  end

  test 'Baseline' do
    assert_equal 9, PaperTrail::Version.count
  end

  context 'Cleaner' do
    context '`clean_versions!` method' do

      should 'removes extra versions for each item' do
        PaperTrail.clean_versions!
        assert_equal 3, PaperTrail::Version.count
        @animals.each { |animal| assert_equal 1, animal.versions.size }
      end

      should 'removes the earliest version(s)' do
        most_recent_version_names = @animals.map { |animal| animal.versions.last.reify.name }
        PaperTrail.clean_versions!
        assert_equal most_recent_version_names, @animals.map { |animal| animal.versions.last.reify.name }
      end

      context '`keep_int` argument' do
        should 'modifies the number of versions ommitted from destruction' do
          PaperTrail.clean_versions!(2)
          assert_equal 6, PaperTrail::Version.all.count
          @animals.each { |animal| assert_equal 2, animal.versions.size }
        end
      end

      context '`date` argument' do
        setup do
          @animal.versions.each { |ver| ver.update_attribute(:created_at, ver.created_at - 1.day) }
          @date = @animal.versions.first.created_at.to_date
          @animal.update_attribute(:name, 'Muppet')
        end

        should 'restrict the version destroyed to those that were created on the date provided' do
          assert_equal 10, PaperTrail::Version.count
          assert_equal 4, @animal.versions.size
          assert_equal 3, @animal.versions_between(@date, @date + 1.day).size
          PaperTrail.clean_versions!(1, @date)
          assert_equal 8, PaperTrail::Version.count
          assert_equal 2, @animal.versions(true).size
          assert_equal @date, @animal.versions.first.created_at.to_date
          assert_equal @date + 1.day, @animal.versions.last.created_at.to_date
        end
      end
    end

  end
end
