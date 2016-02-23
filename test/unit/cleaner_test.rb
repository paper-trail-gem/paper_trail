require "test_helper"

class PaperTrailCleanerTest < ActiveSupport::TestCase
  def populate_db!
    @animals = [@animal = Animal.new, @dog = Dog.new, @cat = Cat.new]
    @animals.each do |animal|
      3.times { animal.update_attribute(:name, FFaker::Name.name) }
    end
  end

  context "`clean_versions!` method" do
    setup { populate_db! }

    should "Baseline" do
      assert_equal 9, PaperTrail::Version.count
      @animals.each { |animal| assert_equal 3, animal.versions.size }
    end

    should "be extended by `PaperTrail` module" do
      assert_respond_to PaperTrail, :clean_versions!
    end

    context "No options provided" do
      should "removes extra versions for each item" do
        PaperTrail.clean_versions!
        assert_equal 3, PaperTrail::Version.count
        @animals.each { |animal| assert_equal 1, animal.versions.size }
      end

      should "removes the earliest version(s)" do
        before = @animals.map { |animal| animal.versions.last.reify.name }
        PaperTrail.clean_versions!
        after = @animals.map { |animal| animal.versions.last.reify.name }
        assert_equal before, after
      end
    end

    context "`:keeping` option" do
      should "modifies the number of versions ommitted from destruction" do
        PaperTrail.clean_versions!(keeping: 2)
        assert_equal 6, PaperTrail::Version.all.count
        @animals.each { |animal| assert_equal 2, animal.versions.size }
      end
    end

    context "`:date` option" do
      setup do
        @animal.versions.each { |ver| ver.update_attribute(:created_at, ver.created_at - 1.day) }
        @date = @animal.versions.first.created_at.to_date
        @animal.update_attribute(:name, FFaker::Name.name)
      end

      should "restrict the versions destroyed to those that were created on the date provided" do
        assert_equal 10, PaperTrail::Version.count
        assert_equal 4, @animal.versions.size
        assert_equal 3, @animal.paper_trail.versions_between(@date, @date + 1.day).size
        PaperTrail.clean_versions!(date: @date)
        assert_equal 8, PaperTrail::Version.count
        assert_equal 2, @animal.versions.reload.size
        assert_equal @date, @animal.versions.first.created_at.to_date
        assert_not_same @date, @animal.versions.last.created_at.to_date
      end
    end

    context "`:item_id` option" do
      context "single ID received" do
        should "restrict the versions destroyed to the versions for the Item with that ID" do
          PaperTrail.clean_versions!(item_id: @animal.id)
          assert_equal 1, @animal.versions.size
          assert_equal 7, PaperTrail::Version.count
        end
      end

      context "collection of ID's received" do
        should "restrict the versions destroyed to the versions for the Item with those ID's" do
          PaperTrail.clean_versions!(item_id: [@animal.id, @dog.id])
          assert_equal 1, @animal.versions.size
          assert_equal 1, @dog.versions.size
          assert_equal 5, PaperTrail::Version.count
        end
      end
    end

    context "options combinations" do # additional tests to cover combinations of options
      context "`:date`" do
        setup do
          [@animal, @dog].each do |animal|
            animal.versions.each { |ver| ver.update_attribute(:created_at, ver.created_at - 1.day) }
            animal.update_attribute(:name, FFaker::Name.name)
          end
          @date = @animal.versions.first.created_at.to_date
        end

        should "Baseline" do
          assert_equal 11, PaperTrail::Version.count
          [@animal, @dog].each do |animal|
            assert_equal 4, animal.versions.size
            assert_equal 3, animal.versions.between(@date, @date + 1.day).size
          end
        end

        context "and `:keeping`" do
          should "restrict cleaning properly" do
            PaperTrail.clean_versions!(date: @date, keeping: 2)
            [@animal, @dog].each do |animal|
              # reload the association to pick up the destructions made by the `Cleaner`
              animal.versions.reload
              assert_equal 3, animal.versions.size
              assert_equal 2, animal.versions.between(@date, @date + 1.day).size
            end
            # ensure that the versions for the `@cat` instance wasn't touched
            assert_equal 9, PaperTrail::Version.count
          end
        end

        context "and `:item_id`" do
          should "restrict cleaning properly" do
            PaperTrail.clean_versions!(date: @date, item_id: @dog.id)
            # reload the association to pick up the destructions made by the `Cleaner`
            @dog.versions.reload
            assert_equal 2, @dog.versions.size
            assert_equal 1, @dog.versions.between(@date, @date + 1.day).size
            # ensure the versions for other animals besides `@animal` weren't touched
            assert_equal 9, PaperTrail::Version.count
          end
        end

        context ", `:item_id`, and `:keeping`" do
          should "restrict cleaning properly" do
            PaperTrail.clean_versions!(date: @date, item_id: @dog.id, keeping: 2)
            # reload the association to pick up the destructions made by the `Cleaner`
            @dog.versions.reload
            assert_equal 3, @dog.versions.size
            assert_equal 2, @dog.versions.between(@date, @date + 1.day).size
            # ensure the versions for other animals besides `@animal` weren't touched
            assert_equal 10, PaperTrail::Version.count
          end
        end
      end

      context "`:keeping` and `:item_id`" do
        should "restrict cleaning properly" do
          PaperTrail.clean_versions!(keeping: 2, item_id: @animal.id)
          assert_equal 2, @animal.versions.size
          # ensure the versions for other animals besides `@animal` weren't touched
          assert_equal 8, PaperTrail::Version.count
        end
      end
    end
  end # clean_versions! method

  context "Custom timestamp field" do
    setup do
      change_schema
      populate_db!
      # now mess with the timestamps
      @animals.each do |animal|
        animal.versions.reverse.each_with_index do |version, index|
          version.update_attribute(:custom_created_at, Time.now.utc + index.days)
        end
      end
      PaperTrail.timestamp_field = :custom_created_at
      @animals.map { |a| a.versions.reload } # reload the `versions` association for each animal
    end

    teardown do
      PaperTrail.timestamp_field = :created_at
      restore_schema
    end

    should "Baseline" do
      assert_equal 9, PaperTrail::Version.count
      @animals.each do |animal|
        assert_equal 3, animal.versions.size
        animal.versions.each_cons(2) do |a, b|
          assert_equal a.created_at.to_date, b.created_at.to_date
          assert_not_equal a.custom_created_at.to_date, b.custom_created_at.to_date
        end
      end
    end

    should "group by `PaperTrail.timestamp_field` when seperating the versions by date to clean" do
      assert_equal 9, PaperTrail::Version.count
      PaperTrail.clean_versions!
      assert_equal 9, PaperTrail::Version.count
    end
  end
end
