require "test_helper"
require "time_travel_helper"

class HasPaperTrailModelTest < ActiveSupport::TestCase
  context "A record with defined 'only' and 'ignore' attributes" do
    setup { @article = Article.create }

    should "creation should change the number of versions" do
      assert_equal(1, PaperTrail::Version.count)
    end

    context "which updates an ignored column" do
      should "not change the number of versions" do
        @article.update_attributes title: "My first title"
        assert_equal(1, PaperTrail::Version.count)
      end
    end

    context "which updates an ignored column with truly Proc" do
      should "not change the number of versions" do
        @article.update_attributes abstract: "ignore abstract"
        assert_equal(1, PaperTrail::Version.count)
      end
    end

    context "which updates an ignored column with falsy Proc" do
      should "change the number of versions" do
        @article.update_attributes abstract: "do not ignore abstract!"
        assert_equal(2, PaperTrail::Version.count)
      end
    end

    context "which updates an ignored column, ignored with truly Proc and a selected column" do
      setup do
        @article.update_attributes(
          title: "My first title",
          content: "Some text here.",
          abstract: "ignore abstract"
        )
      end

      should "change the number of versions" do
        assert_equal(2, PaperTrail::Version.count)
      end

      should "show the new version in the model's `versions` association" do
        assert_equal(2, @article.versions.size)
      end

      should "have stored only non-ignored attributes" do
        expected = { "content" => [nil, "Some text here."] }
        assert_equal expected, @article.versions.last.changeset
      end
    end

    context "which updates an ignored column, ignored with falsy Proc and a selected column" do
      setup do
        @article.update_attributes(
          title: "My first title",
          content: "Some text here.",
          abstract: "do not ignore abstract"
        )
      end

      should "change the number of versions" do
        assert_equal(2, PaperTrail::Version.count)
      end

      should "show the new version in the model's `versions` association" do
        assert_equal(2, @article.versions.size)
      end

      should "have stored only non-ignored attributes" do
        expected = {
          "content" => [nil, "Some text here."],
          "abstract" => [nil, "do not ignore abstract"]
        }
        assert_equal expected, @article.versions.last.changeset
      end
    end

    context "which updates a selected column" do
      setup { @article.update_attributes content: "Some text here." }
      should "change the number of versions" do
        assert_equal(2, PaperTrail::Version.count)
      end

      should "show the new version in the model's `versions` association" do
        assert_equal(2, @article.versions.size)
      end
    end

    context "which updates a non-ignored and non-selected column" do
      should "not change the number of versions" do
        @article.update_attributes abstract: "Other abstract"
        assert_equal(1, PaperTrail::Version.count)
      end
    end

    context "which updates a skipped column" do
      should "not change the number of versions" do
        @article.update_attributes file_upload: "Your data goes here"
        assert_equal(1, PaperTrail::Version.count)
      end
    end

    context "which updates a skipped column and a selected column" do
      setup do
        @article.update_attributes(
          file_upload: "Your data goes here",
          content: "Some text here."
        )
      end

      should "change the number of versions" do
        assert_equal(2, PaperTrail::Version.count)
      end

      should "show the new version in the model's `versions` association" do
        assert_equal(2, @article.versions.size)
      end

      should "have stored only non-skipped attributes" do
        assert_equal ({ "content" => [nil, "Some text here."] }),
          @article.versions.last.changeset
      end

      context "and when updated again" do
        setup do
          @article.update_attributes(
            file_upload: "More data goes here",
            content: "More text here."
          )
          @old_article = @article.versions.last
        end

        should "have removed the skipped attributes when saving the previous version" do
          assert_equal nil, PaperTrail.serializer.load(@old_article.object)["file_upload"]
        end

        should "have kept the non-skipped attributes in the previous version" do
          assert_equal "Some text here.", PaperTrail.serializer.load(@old_article.object)["content"]
        end
      end
    end

    context "which gets destroyed" do
      setup { @article.destroy }
      should "change the number of versions" do assert_equal(2, PaperTrail::Version.count) end

      should "show the new version in the model's `versions` association" do
        assert_equal(2, @article.versions.size)
      end
    end
  end

  context "A record with defined 'ignore' attribute" do
    setup { @legacy_widget = LegacyWidget.create }

    context "which updates an ignored column" do
      setup { @legacy_widget.update_attributes version: 1 }
      should "not change the number of versions" do assert_equal(1, PaperTrail::Version.count) end
    end
  end

  context 'A record with defined "if" and "unless" attributes' do
    setup { @translation = Translation.new headline: "Headline" }

    context "for non-US translations" do
      setup { @translation.save }
      should "not change the number of versions" do assert_equal(0, PaperTrail::Version.count) end

      context "after update" do
        setup { @translation.update_attributes content: "Content" }
        should "not change the number of versions" do assert_equal(0, PaperTrail::Version.count) end
      end

      context "after destroy" do
        setup { @translation.destroy }
        should "not change the number of versions" do assert_equal(0, PaperTrail::Version.count) end
      end
    end

    context "for US translations" do
      setup { @translation.language_code = "US" }

      context "that are drafts" do
        setup do
          @translation.type = "DRAFT"
          @translation.save
        end

        should "not change the number of versions" do
          assert_equal(0, PaperTrail::Version.count)
        end

        context "after update" do
          setup { @translation.update_attributes content: "Content" }
          should "not change the number of versions" do
            assert_equal(0, PaperTrail::Version.count)
          end
        end
      end

      context "that are not drafts" do
        setup { @translation.save }

        should "change the number of versions" do
          assert_equal(1, PaperTrail::Version.count)
        end

        context "after update" do
          setup { @translation.update_attributes content: "Content" }
          should "change the number of versions" do
            assert_equal(2, PaperTrail::Version.count)
          end

          should "show the new version in the model's `versions` association" do
            assert_equal(2, @translation.versions.size)
          end
        end

        context "after destroy" do
          setup { @translation.destroy }
          should "change the number of versions" do
            assert_equal(2, PaperTrail::Version.count)
          end

          should "show the new version in the model's `versions` association" do
            assert_equal(2, @translation.versions.size)
          end
        end
      end
    end
  end

  context "A new record" do
    setup { @widget = Widget.new }

    should "not have any previous versions" do
      assert_equal [], @widget.versions
    end

    should "be live" do
      assert @widget.paper_trail.live?
    end

    context "which is then created" do
      setup { @widget.update_attributes name: "Henry", created_at: Time.now - 1.day }

      should "have one previous version" do
        assert_equal 1, @widget.versions.length
      end

      should "be nil in its previous version" do
        assert_nil @widget.versions.first.object
        assert_nil @widget.versions.first.reify
      end

      should "record the correct event" do
        assert_match(/create/i, @widget.versions.first.event)
      end

      should "be live" do
        assert @widget.paper_trail.live?
      end

      should "use the widget `updated_at` as the version's `created_at`" do
        assert_equal @widget.updated_at.to_i, @widget.versions.first.created_at.to_i
      end

      should "have changes" do
        # TODO: Postgres does not appear to pass back
        # ActiveSupport::TimeWithZone, so choosing the lowest common denominator
        # to test.

        changes = {
          "name" => [nil, "Henry"],
          "created_at" => [nil, @widget.created_at.to_time.utc],
          "updated_at" => [nil, @widget.updated_at.to_time.utc],
          "id" => [nil, @widget.id]
        }

        assert_kind_of Time, @widget.versions.last.changeset["updated_at"][1]
        assert_changes_equal changes, @widget.versions.last.changeset
      end

      context "and then updated without any changes" do
        setup { @widget.touch }

        should "not have a new version" do
          assert_equal 1, @widget.versions.length
        end
      end

      context "and then updated with changes" do
        setup { @widget.update_attributes name: "Harry" }

        should "have two previous versions" do
          assert_equal 2, @widget.versions.length
        end

        should "be available in its previous version" do
          assert_equal "Harry", @widget.name
          assert_not_nil @widget.versions.last.object
          widget = @widget.versions.last.reify
          assert_equal "Henry", widget.name
          assert_equal "Harry", @widget.name
        end

        should "have the same ID in its previous version" do
          assert_equal @widget.id, @widget.versions.last.reify.id
        end

        should "record the correct event" do
          assert_match(/update/i, @widget.versions.last.event)
        end

        should "have versions that are not live" do
          assert @widget.versions.map(&:reify).compact.all? { |w|
            !w.paper_trail.live?
          }
        end

        should "have stored changes" do
          # Behavior for ActiveRecord 4 is different than ActiveRecord 3;
          # AR4 includes the `updated_at` column in changes for updates, which
          # is why we reject it from the right side of this assertion.
          last_obj_changes = @widget.versions.last.object_changes
          actual = PaperTrail.serializer.load(last_obj_changes).reject { |k, _v|
            k.to_sym == :updated_at
          }
          assert_equal ({ "name" => %w(Henry Harry) }), actual
          actual = @widget.versions.last.changeset.reject { |k, _v|
            k.to_sym == :updated_at
          }
          assert_equal ({ "name" => %w(Henry Harry) }), actual
        end

        should "return changes with indifferent access" do
          assert_equal %w(Henry Harry), @widget.versions.last.changeset[:name]
          assert_equal %w(Henry Harry), @widget.versions.last.changeset["name"]
        end

        context "and has one associated object" do
          setup do
            @wotsit = @widget.create_wotsit name: "John"
          end

          should "not copy the has_one association by default when reifying" do
            reified_widget = @widget.versions.last.reify
            # association hasn't been affected by reifying
            assert_equal @wotsit, reified_widget.wotsit
            # confirm that the association is correct
            assert_equal @wotsit, @widget.reload.wotsit
          end

          should "copy the has_one association when reifying with :has_one => true" do
            reified_widget = @widget.versions.last.reify(has_one: true)
            # wotsit wasn't there at the last version
            assert_nil reified_widget.wotsit
            # wotsit should still exist on live object
            assert_equal @wotsit, @widget.reload.wotsit
          end
        end

        context "and has many associated objects" do
          setup do
            @f0 = @widget.fluxors.create name: "f-zero"
            @f1 = @widget.fluxors.create name: "f-one"
            @reified_widget = @widget.versions.last.reify
          end

          should "copy the has_many associations when reifying" do
            assert_equal @widget.fluxors.length, @reified_widget.fluxors.length
            assert_same_elements @widget.fluxors, @reified_widget.fluxors

            assert_equal @widget.versions.length, @reified_widget.versions.length
            assert_same_elements @widget.versions, @reified_widget.versions
          end
        end

        context "and has many associated polymorphic objects" do
          setup do
            @f0 = @widget.whatchamajiggers.create name: "f-zero"
            @f1 = @widget.whatchamajiggers.create name: "f-zero"
            @reified_widget = @widget.versions.last.reify
          end

          should "copy the has_many associations when reifying" do
            assert_equal @widget.whatchamajiggers.length, @reified_widget.whatchamajiggers.length
            assert_same_elements @widget.whatchamajiggers, @reified_widget.whatchamajiggers

            assert_equal @widget.versions.length, @reified_widget.versions.length
            assert_same_elements @widget.versions, @reified_widget.versions
          end
        end

        context "polymorphic objects by themselves" do
          setup do
            @widget = Whatchamajigger.new name: "f-zero"
          end

          should "not fail with a nil pointer on the polymorphic association" do
            @widget.save!
          end
        end

        context "and then destroyed" do
          setup do
            @fluxor = @widget.fluxors.create name: "flux"
            @widget.destroy
            @reified_widget = PaperTrail::Version.last.reify
          end

          should "record the correct event" do
            assert_match(/destroy/i, PaperTrail::Version.last.event)
          end

          should "have three previous versions" do
            assert_equal 3, PaperTrail::Version.with_item_keys("Widget", @widget.id).length
          end

          should "be available in its previous version" do
            assert_equal @widget.id, @reified_widget.id
            assert_attributes_equal @widget.attributes, @reified_widget.attributes
          end

          should "be re-creatable from its previous version" do
            assert @reified_widget.save
          end

          should "restore its associations on its previous version" do
            @reified_widget.save
            assert_equal 1, @reified_widget.fluxors.length
          end

          should "have nil item for last version" do
            assert_nil(@widget.versions.last.item)
          end

          should "not have changes" do
            assert_equal({}, @widget.versions.last.changeset)
          end
        end
      end
    end
  end

  # Test the serialisation and deserialisation.
  # TODO: binary
  context "A record's papertrail" do
    setup do
      @date_time = DateTime.now.utc
      @time = Time.now
      @date = Date.new 2009, 5, 29
      @widget = Widget.create(
        name: "Warble",
        a_text: "The quick brown fox",
        an_integer: 42,
        a_float: 153.01,
        a_decimal: 2.71828,
        a_datetime: @date_time,
        a_time: @time,
        a_date: @date,
        a_boolean: true
      )
      @widget.update_attributes(
        name: nil,
        a_text: nil,
        an_integer: nil,
        a_float: nil,
        a_decimal: nil,
        a_datetime: nil,
        a_time: nil,
        a_date: nil,
        a_boolean: false
      )
      @previous = @widget.versions.last.reify
    end

    should "handle strings" do
      assert_equal "Warble", @previous.name
    end

    should "handle text" do
      assert_equal "The quick brown fox", @previous.a_text
    end

    should "handle integers" do
      assert_equal 42, @previous.an_integer
    end

    should "handle floats" do
      assert_in_delta 153.01, @previous.a_float, 0.001
    end

    should "handle decimals" do
      assert_in_delta 2.7183, @previous.a_decimal, 0.0001
    end

    should "handle datetimes" do
      assert_equal @date_time.to_time.utc.to_i, @previous.a_datetime.to_time.utc.to_i
    end

    should "handle times" do
      assert_equal @time.utc.to_i, @previous.a_time.utc.to_i
    end

    should "handle dates" do
      assert_equal @date, @previous.a_date
    end

    should "handle booleans" do
      assert @previous.a_boolean
    end

    context "after a column is removed from the record's schema" do
      setup do
        change_schema
        Widget.connection.schema_cache.clear!
        Widget.reset_column_information
        assert_raise(NoMethodError) { Widget.new.sacrificial_column }
        @last = @widget.versions.last
      end

      teardown do
        restore_schema
      end

      should "reify previous version" do
        assert_kind_of Widget, @last.reify
      end

      should "restore all forward-compatible attributes" do
        assert_equal    "Warble",                    @last.reify.name
        assert_equal    "The quick brown fox",       @last.reify.a_text
        assert_equal    42,                          @last.reify.an_integer
        assert_in_delta 153.01,                      @last.reify.a_float,   0.001
        assert_in_delta 2.7183,                      @last.reify.a_decimal, 0.0001
        assert_equal    @date_time.to_time.utc.to_i, @last.reify.a_datetime.to_time.utc.to_i
        assert_equal    @time.utc.to_i,              @last.reify.a_time.utc.to_i
        assert_equal    @date,                       @last.reify.a_date
        assert          @last.reify.a_boolean
      end
    end
  end

  context "A record" do
    setup { @widget = Widget.create name: "Zaphod" }

    context "with PaperTrail globally disabled" do
      setup do
        PaperTrail.enabled = false
        @count = @widget.versions.length
      end

      teardown { PaperTrail.enabled = true }

      context "when updated" do
        setup { @widget.update_attributes name: "Beeblebrox" }

        should "not add to its trail" do
          assert_equal @count, @widget.versions.length
        end
      end
    end

    context "with its paper trail turned off" do
      setup do
        Widget.paper_trail.disable
        @count = @widget.versions.length
      end

      teardown { Widget.paper_trail.enable }

      context "when updated" do
        setup { @widget.update_attributes name: "Beeblebrox" }

        should "not add to its trail" do
          assert_equal @count, @widget.versions.length
        end
      end

      context 'when destroyed "without versioning"' do
        should "leave paper trail off after call" do
          @widget.paper_trail.without_versioning :destroy
          assert_equal false, Widget.paper_trail.enabled?
        end
      end

      context "and then its paper trail turned on" do
        setup { Widget.paper_trail.enable }

        context "when updated" do
          setup { @widget.update_attributes name: "Ford" }

          should "add to its trail" do
            assert_equal @count + 1, @widget.versions.length
          end
        end

        context 'when updated "without versioning"' do
          setup do
            @widget.paper_trail.without_versioning do
              @widget.update_attributes name: "Ford"
            end
            # The model instance should yield itself for convenience purposes
            @widget.paper_trail.without_versioning { |w| w.update_attributes name: "Nixon" }
          end

          should "not create new version" do
            assert_equal @count, @widget.versions.length
          end

          should "enable paper trail after call" do
            assert Widget.paper_trail.enabled?
          end
        end

        context "when receiving a method name as an argument" do
          setup { @widget.paper_trail.without_versioning(:touch_with_version) }

          should "not create new version" do
            assert_equal @count, @widget.versions.length
          end

          should "enable paper trail after call" do
            assert Widget.paper_trail.enabled?
          end
        end
      end
    end
  end

  context "A papertrail with somebody making changes" do
    setup do
      @widget = Widget.new name: "Fidget"
    end

    context "when a record is created" do
      setup do
        PaperTrail.whodunnit = "Alice"
        @widget.save
        @version = @widget.versions.last # only 1 version
      end

      should "track who made the change" do
        assert_equal "Alice", @version.whodunnit
        assert_nil @version.paper_trail_originator
        assert_equal "Alice", @version.terminator
        assert_equal "Alice", @widget.paper_trail.originator
      end

      context "when a record is updated" do
        setup do
          PaperTrail.whodunnit = "Bob"
          @widget.update_attributes name: "Rivet"
          @version = @widget.versions.last
        end

        should "track who made the change" do
          assert_equal "Bob", @version.whodunnit
          assert_equal "Alice", @version.paper_trail_originator
          assert_equal "Bob", @version.terminator
          assert_equal "Bob", @widget.paper_trail.originator
        end

        context "when a record is destroyed" do
          setup do
            PaperTrail.whodunnit = "Charlie"
            @widget.destroy
            @version = PaperTrail::Version.last
          end

          should "track who made the change" do
            assert_equal "Charlie", @version.whodunnit
            assert_equal "Bob", @version.paper_trail_originator
            assert_equal "Charlie", @version.terminator
            assert_equal "Charlie", @widget.paper_trail.originator
          end
        end
      end
    end
  end

  context "Timestamps" do
    setup do
      @wotsit = Wotsit.create! name: "wotsit"
    end

    should "record timestamps" do
      @wotsit.update_attributes! name: "changed"
      assert_not_nil @wotsit.versions.last.reify.created_at
      assert_not_nil @wotsit.versions.last.reify.updated_at
    end

    # Tests that it doesn't try to write created_on as an attribute just because
    # a created_on method exists.
    #
    # - Deprecation warning in Rails 3.2
    # - ActiveModel::MissingAttributeError in Rails 4
    #
    # In rails 5, `capture` is deprecated in favor of `capture_io`.
    #
    should "not generate warning" do
      assert_update_raises_nothing = lambda {
        assert_nothing_raised {
          @wotsit.update_attributes! name: "changed"
        }
      }
      warnings =
        if respond_to?(:capture_io)
          capture_io { assert_update_raises_nothing.call }.last
        else
          capture(:stderr) { assert_update_raises_nothing.call }
        end
      assert_equal "", warnings
    end
  end

  context "A subclass" do
    setup do
      @foo = FooWidget.create
      @foo.update_attributes! name: "Foo"
    end

    should "reify with the correct type" do
      # For some reason this test appears to be broken on AR4 in the test env.
      # Executing it manually in the Rails console seems to work.. not sure what
      # the issues is here.
      assert_kind_of FooWidget, @foo.versions.last.reify if ActiveRecord::VERSION::MAJOR < 4
      assert_equal @foo.versions.first, PaperTrail::Version.last.previous
      assert_nil PaperTrail::Version.last.next
    end

    should "should return the correct originator" do
      PaperTrail.whodunnit = "Ben"
      @foo.update_attribute(:name, "Geoffrey")
      assert_equal PaperTrail.whodunnit, @foo.paper_trail.originator
    end

    context "when destroyed" do
      setup { @foo.destroy }

      should "reify with the correct type" do
        assert_kind_of FooWidget, @foo.versions.last.reify
        assert_equal @foo.versions[1], PaperTrail::Version.last.previous
        assert_nil PaperTrail::Version.last.next
      end
    end
  end

  context "An item with versions" do
    setup do
      @widget = Widget.create name: "Widget"
      @widget.update_attributes name: "Fidget"
      @widget.update_attributes name: "Digit"
    end

    context "which were created over time" do
      setup do
        @created = 2.days.ago
        @first_update = 1.day.ago
        @second_update = 1.hour.ago
        @widget.versions[0].update_attributes created_at: @created
        @widget.versions[1].update_attributes created_at: @first_update
        @widget.versions[2].update_attributes created_at: @second_update
        @widget.update_attribute :updated_at, @second_update
      end

      should "return nil for version_at before it was created" do
        assert_nil @widget.paper_trail.version_at(@created - 1)
      end

      should "return how it looked when created for version_at its creation" do
        assert_equal "Widget", @widget.paper_trail.version_at(@created).name
      end

      should "return how it looked before its first update" do
        assert_equal "Widget", @widget.paper_trail.version_at(@first_update - 1).name
      end

      should "return how it looked after its first update" do
        assert_equal "Fidget", @widget.paper_trail.version_at(@first_update).name
      end

      should "return how it looked before its second update" do
        assert_equal "Fidget", @widget.paper_trail.version_at(@second_update - 1).name
      end

      should "return how it looked after its second update" do
        assert_equal "Digit", @widget.paper_trail.version_at(@second_update).name
      end

      should "return the current object for version_at after latest update" do
        assert_equal "Digit", @widget.paper_trail.version_at(1.day.from_now).name
      end

      context "passing in a string representation of a timestamp" do
        should "still return a widget when appropriate" do
          # need to add 1 second onto the timestamps before casting to a string,
          # since casting a Time to a string drops the microseconds
          assert_equal "Widget",
            @widget.paper_trail.version_at((@created + 1.second).to_s).name
          assert_equal "Fidget",
            @widget.paper_trail.version_at((@first_update + 1.second).to_s).name
          assert_equal "Digit",
            @widget.paper_trail.version_at((@second_update + 1.second).to_s).name
        end
      end
    end

    context ".versions_between" do
      setup do
        @created = 30.days.ago
        @first_update = 15.days.ago
        @second_update = 1.day.ago
        @widget.versions[0].update_attributes created_at: @created
        @widget.versions[1].update_attributes created_at: @first_update
        @widget.versions[2].update_attributes created_at: @second_update
        @widget.update_attribute :updated_at, @second_update
      end

      should "return versions in the time period" do
        assert_equal ["Fidget"],
          @widget.paper_trail.versions_between(20.days.ago, 10.days.ago).map(&:name)
        assert_equal %w(Widget Fidget),
          @widget.paper_trail.versions_between(45.days.ago, 10.days.ago).map(&:name)
        assert_equal %w(Fidget Digit Digit),
          @widget.paper_trail.versions_between(16.days.ago, 1.minute.ago).map(&:name)
        assert_equal [],
          @widget.paper_trail.versions_between(60.days.ago, 45.days.ago).map(&:name)
      end
    end

    context "on the first version" do
      setup { @version = @widget.versions.first }

      should "have a nil previous version" do
        assert_nil @version.previous
      end

      should "return the next version" do
        assert_equal @widget.versions[1], @version.next
      end

      should "return the correct index" do
        assert_equal 0, @version.index
      end
    end

    context "on the last version" do
      setup { @version = @widget.versions.last }

      should "return the previous version" do
        assert_equal @widget.versions[@widget.versions.length - 2], @version.previous
      end

      should "have a nil next version" do
        assert_nil @version.next
      end

      should "return the correct index" do
        assert_equal @widget.versions.length - 1, @version.index
      end
    end
  end

  context "An item" do
    setup do
      @initial_title = "Foobar"
      @article = Article.new title: @initial_title
    end

    context "which is created" do
      setup { @article.save }

      should "store fixed meta data" do
        assert_equal 42, @article.versions.last.answer
      end

      should "store dynamic meta data which is independent of the item" do
        assert_equal "31 + 11 = 42", @article.versions.last.question
      end

      should "store dynamic meta data which depends on the item" do
        assert_equal @article.id, @article.versions.last.article_id
      end

      should "store dynamic meta data based on a method of the item" do
        assert_equal @article.action_data_provider_method, @article.versions.last.action
      end

      should "store dynamic meta data based on an attribute of the item at creation" do
        assert_equal @initial_title, @article.versions.last.title
      end

      context "and updated" do
        setup do
          @article.update_attributes! content: "Better text.", title: "Rhubarb"
        end

        should "store fixed meta data" do
          assert_equal 42, @article.versions.last.answer
        end

        should "store dynamic meta data which is independent of the item" do
          assert_equal "31 + 11 = 42", @article.versions.last.question
        end

        should "store dynamic meta data which depends on the item" do
          assert_equal @article.id, @article.versions.last.article_id
        end

        should "store dynamic meta data based on an attribute of the item prior to the update" do
          assert_equal @initial_title, @article.versions.last.title
        end
      end

      context "and destroyed" do
        setup { @article.destroy }

        should "store fixed metadata" do
          assert_equal 42, @article.versions.last.answer
        end

        should "store dynamic metadata which is independent of the item" do
          assert_equal "31 + 11 = 42", @article.versions.last.question
        end

        should "store dynamic metadata which depends on the item" do
          assert_equal @article.id, @article.versions.last.article_id
        end

        should "store dynamic metadata based on attribute of item prior to destruction" do
          assert_equal @initial_title, @article.versions.last.title
        end
      end
    end
  end

  context "A reified item" do
    setup do
      widget = Widget.create name: "Bob"
      %w( Tom Dick Jane ).each { |name| widget.update_attributes name: name }
      @version = widget.versions.last
      @widget = @version.reify
    end

    should "know which version it came from" do
      assert_equal @version, @widget.version
    end

    should "return its previous self" do
      assert_equal @widget.versions[-2].reify,
        @widget.paper_trail.previous_version
    end
  end

  context "A non-reified item" do
    setup { @widget = Widget.new }

    should "not have a previous version" do
      assert_nil @widget.paper_trail.previous_version
    end

    should "not have a next version" do
      assert_nil @widget.paper_trail.next_version
    end

    context "with versions" do
      setup do
        @widget.save
        %w( Tom Dick Jane ).each { |name| @widget.update_attributes name: name }
      end

      should "have a previous version" do
        assert_equal @widget.versions.last.reify.name,
          @widget.paper_trail.previous_version.name
      end

      should "not have a next version" do
        assert_nil @widget.paper_trail.next_version
      end
    end
  end

  context "A reified item" do
    setup do
      @widget = Widget.create name: "Bob"
      %w(Tom Dick Jane).each { |name| @widget.update_attributes name: name }
      @second_widget = @widget.versions[1].reify # first widget is `nil`
      @last_widget = @widget.versions.last.reify
    end

    should "have a previous version" do
      # `create` events return `nil` for `reify`
      assert_nil @second_widget.paper_trail.previous_version
      assert_equal @widget.versions[-2].reify.name,
        @last_widget.paper_trail.previous_version.name
    end

    should "have a next version" do
      assert_equal @widget.versions[2].reify.name, @second_widget.paper_trail.next_version.name
      assert_equal @last_widget.paper_trail.next_version.name, @widget.name
    end
  end

  context ":has_many :through" do
    setup do
      @book = Book.create title: "War and Peace"
      @dostoyevsky = Person.create name: "Dostoyevsky"
      @solzhenitsyn = Person.create name: "Solzhenitsyn"
    end

    should "store version on source <<" do
      count = PaperTrail::Version.count
      @book.authors << @dostoyevsky
      assert_equal 1, PaperTrail::Version.count - count
      assert_equal PaperTrail::Version.last, @book.authorships.first.versions.first
    end

    should "store version on source create" do
      count = PaperTrail::Version.count
      @book.authors.create name: "Tolstoy"
      assert_equal 2, PaperTrail::Version.count - count
      actual = [
        PaperTrail::Version.order(:id).to_a[-2].item,
        PaperTrail::Version.last.item
      ]
      assert_same_elements [Person.last, Authorship.last], actual
    end

    should "store version on join destroy" do
      @book.authors << @dostoyevsky
      count = PaperTrail::Version.count
      @book.authorships.reload.last.destroy
      assert_equal 1, PaperTrail::Version.count - count
      assert_equal @book, PaperTrail::Version.last.reify.book
      assert_equal @dostoyevsky, PaperTrail::Version.last.reify.author
    end

    should "store version on join clear" do
      @book.authors << @dostoyevsky
      count = PaperTrail::Version.count
      @book.authorships.reload.destroy_all
      assert_equal 1, PaperTrail::Version.count - count
      assert_equal @book, PaperTrail::Version.last.reify.book
      assert_equal @dostoyevsky, PaperTrail::Version.last.reify.author
    end
  end

  context "When an attribute has a custom serializer" do
    setup do
      @person = Person.new(time_zone: "Samoa")
    end

    should "be an instance of ActiveSupport::TimeZone" do
      assert_equal ActiveSupport::TimeZone, @person.time_zone.class
    end

    context "when the model is saved" do
      setup do
        @changes_before_save = @person.changes.dup
        @person.save!
      end

      # Test for serialization:
      should "version.object_changes should store long serialization of TimeZone object" do
        len = @person.versions.last.object_changes.length
        assert len < 105, "object_changes length was #{len}"
      end

      # It should store the serialized value.
      should "version.object_changes attribute should have stored the value from serializer" do
        as_stored_in_version = HashWithIndifferentAccess[
          YAML.load(@person.versions.last.object_changes)
        ]
        assert_equal [nil, "Samoa"], as_stored_in_version[:time_zone]
        serialized_value = Person::TimeZoneSerializer.dump(@person.time_zone)
        assert_equal serialized_value, as_stored_in_version[:time_zone].last
      end

      # Tests for unserialization:
      should "version.changeset should convert attribute to original, unserialized value" do
        unserialized_value = Person::TimeZoneSerializer.load(@person.time_zone)
        assert_equal unserialized_value,
          @person.versions.last.changeset[:time_zone].last
      end

      should "record.changes (before save) returns the original, unserialized values" do
        assert_equal [NilClass, ActiveSupport::TimeZone],
          @changes_before_save[:time_zone].map(&:class)
      end

      should "version.changeset should be the same as record.changes was before the save" do
        actual = @person.versions.last.changeset.delete_if { |k, _v| k.to_sym == :id }
        assert_equal @changes_before_save, actual
        actual = @person.versions.last.changeset[:time_zone].map(&:class)
        assert_equal [NilClass, ActiveSupport::TimeZone], actual
      end

      context "when that attribute is updated" do
        setup do
          @attribute_value_before_change = @person.time_zone
          @person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
          @changes_before_save = @person.changes.dup
          @person.save!
        end

        # Tests for serialization
        # -----------------------
        #
        # Before the serialized attributes fix, the object/object_changes value
        # that was stored was ridiculously long (58723).
        #
        # version.object should not have stored the default, ridiculously long
        # (to_yaml) serialization of the TimeZone object.
        should "object should not store long serialization of TimeZone object" do
          len = @person.versions.last.object.length
          assert len < 105, "object length was #{len}"
        end

        # Need an additional clause to detect what version of ActiveRecord is
        # being used for this test because AR4 injects the `updated_at` column
        # into the changeset for updates to models.
        #
        # version.object_changes should not have stored the default,
        # ridiculously long (to_yaml) serialization of the TimeZone object
        should "object_changes should not store long serialization of TimeZone object" do
          max_len = ActiveRecord::VERSION::MAJOR < 4 ? 105 : 118
          len = @person.versions.last.object_changes.length
          assert len < max_len, "object_changes length was #{len}"
        end

        # But now it stores the short, serialized value.
        should "version.object attribute should have stored value from serializer" do
          as_stored_in_version = HashWithIndifferentAccess[
            YAML.load(@person.versions.last.object)
          ]
          assert_equal "Samoa", as_stored_in_version[:time_zone]
          serialized_value = Person::TimeZoneSerializer.dump(@attribute_value_before_change)
          assert_equal serialized_value, as_stored_in_version[:time_zone]
        end

        should "version.object_changes attribute should have stored value from serializer" do
          as_stored_in_version = HashWithIndifferentAccess[
            YAML.load(@person.versions.last.object_changes)
          ]
          assert_equal ["Samoa", "Pacific Time (US & Canada)"], as_stored_in_version[:time_zone]
          serialized_value = Person::TimeZoneSerializer.dump(@person.time_zone)
          assert_equal serialized_value, as_stored_in_version[:time_zone].last
        end

        # Tests for unserialization:
        should "version.reify should convert attribute to original, unserialized value" do
          unserialized_value = Person::TimeZoneSerializer.load(@attribute_value_before_change)
          assert_equal unserialized_value,
            @person.versions.last.reify.time_zone
        end

        should "version.changeset should convert attribute to original, unserialized value" do
          unserialized_value = Person::TimeZoneSerializer.load(@person.time_zone)
          assert_equal unserialized_value,
            @person.versions.last.changeset[:time_zone].last
        end

        should "record.changes (before save) returns the original, unserialized values" do
          assert_equal [ActiveSupport::TimeZone, ActiveSupport::TimeZone],
            @changes_before_save[:time_zone].map(&:class)
        end

        should "version.changeset should be the same as record.changes was before the save" do
          assert_equal @changes_before_save, @person.versions.last.changeset
          assert_equal [ActiveSupport::TimeZone, ActiveSupport::TimeZone],
            @person.versions.last.changeset[:time_zone].map(&:class)
        end
      end
    end
  end

  context "A new model instance which uses a custom PaperTrail::Version class" do
    setup { @post = Post.new }

    context "which is then saved" do
      setup { @post.save }
      should "change the number of post versions" do assert_equal 1, PostVersion.count end
      should "not change the number of versions" do assert_equal(0, PaperTrail::Version.count) end
    end
  end

  context "An existing model instance which uses a custom PaperTrail::Version class" do
    setup { @post = Post.create }
    should "have one post version" do assert_equal(1, PostVersion.count) end

    context "on the first version" do
      setup { @version = @post.versions.first }

      should "have the correct index" do
        assert_equal 0, @version.index
      end
    end

    should "have versions of the custom class" do
      assert_equal "PostVersion", @post.versions.first.class.name
    end

    context "which is modified" do
      setup do
        @post.update_attributes(content: "Some new content")
      end

      should "change the number of post versions" do
        assert_equal(2, PostVersion.count)
      end

      should "not change the number of versions" do
        assert_equal(0, PaperTrail::Version.count)
      end

      should "not have stored changes when object_changes column doesn't exist" do
        assert_nil @post.versions.last.changeset
      end
    end
  end

  context "An overwritten default accessor" do
    setup do
      @song = Song.create length: 4
      @song.update_attributes length: 5
    end

    should 'return "overwritten" value on live instance' do
      assert_equal 5, @song.length
    end
    should 'return "overwritten" value on reified instance' do
      assert_equal 4, @song.versions.last.reify.length
    end

    context "Has a virtual attribute injected into the ActiveModel::Dirty changes" do
      setup do
        @song.name = "Good Vibrations"
        @song.save
        @song.name = "Yellow Submarine"
      end

      should "return persist the changes on the live instance properly" do
        assert_equal "Yellow Submarine", @song.name
      end
      should 'return "overwritten" virtual attribute on the reified instance' do
        assert_equal "Good Vibrations", @song.versions.last.reify.name
      end
    end
  end

  context "An unsaved record" do
    setup do
      @widget = Widget.new
      @widget.destroy
    end
    should "not have a version created on destroy" do
      assert @widget.versions.empty?
    end
  end

  context "A model with a custom association" do
    setup do
      @doc = Document.create
      @doc.update_attributes name: "Doc 1"
    end

    should "not respond to versions method" do
      assert !@doc.respond_to?(:versions)
    end

    should "create a new version record" do
      assert_equal 2, @doc.paper_trail_versions.length
    end

    should "respond to `next_version` as normal" do
      reified = @doc.paper_trail_versions.last.reify
      assert_equal reified.paper_trail.next_version.name, @doc.name
    end

    should "respond to `previous_version` as normal" do
      @doc.update_attributes name: "Doc 2"
      assert_equal 3, @doc.paper_trail_versions.length
      assert_equal "Doc 1", @doc.paper_trail.previous_version.name
    end
  end

  context "The `on` option" do
    context "on create" do
      setup do
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:create]
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes name: "blah"
        @fluxor.destroy
      end
      should "only have a version for the create event" do
        assert_equal 1, @fluxor.versions.length
        assert_equal "create", @fluxor.versions.last.event
      end
    end
    context "on update" do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:update]
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes name: "blah"
        @fluxor.destroy
      end
      should "only have a version for the update event" do
        assert_equal 1, @fluxor.versions.length
        assert_equal "update", @fluxor.versions.last.event
      end
    end
    context "on destroy" do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:destroy]
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes name: "blah"
        @fluxor.destroy
      end
      should "only have a version for the destroy event" do
        assert_equal 1, @fluxor.versions.length
        assert_equal "destroy", @fluxor.versions.last.event
      end
    end
    context "on []" do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => []
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes name: "blah"
      end

      teardown do
        @fluxor.destroy
      end

      should "not have any versions" do
        assert_equal 0, @fluxor.versions.length
      end

      should "still respond to touch_with_version" do
        @fluxor.paper_trail.touch_with_version
        assert_equal 1, @fluxor.versions.length
      end
    end
    context "allows a symbol to be passed" do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => :create
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes name: "blah"
        @fluxor.destroy
      end
      should "only have a version for hte create event" do
        assert_equal 1, @fluxor.versions.length
        assert_equal "create", @fluxor.versions.last.event
      end
    end
  end

  context "A model with column version and custom version_method" do
    setup do
      @legacy_widget = LegacyWidget.create(name: "foo", version: 2)
    end

    should "set version on create" do
      assert_equal 2, @legacy_widget.version
    end

    should "allow version updates" do
      @legacy_widget.update_attributes version: 3
      assert_equal 3, @legacy_widget.version
    end

    should "create a new version record" do
      assert_equal 1, @legacy_widget.versions.size
    end
  end

  context "A reified item with a column -version- and custom version_method" do
    setup do
      widget = LegacyWidget.create(name: "foo", version: 2)
      %w( bar baz ).each { |name| widget.update_attributes name: name }
      @version = widget.versions.last
      @widget = @version.reify
    end

    should "know which version it came from" do
      assert_equal @version, @widget.custom_version
    end

    should "return its previous self" do
      assert_equal @widget.versions[-2].reify, @widget.paper_trail.previous_version
    end
  end

  context "custom events" do
    context "on create" do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:create]
        END
        @fluxor = Fluxor.new.tap { |model| model.paper_trail_event = "created" }
        @fluxor.update_attributes name: "blah"
        @fluxor.destroy
      end
      should "only have a version for the created event" do
        assert_equal 1, @fluxor.versions.length
        assert_equal "created", @fluxor.versions.last.event
      end
    end
    context "on update" do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:update]
        END
        @fluxor = Fluxor.create.tap { |model| model.paper_trail_event = "name_updated" }
        @fluxor.update_attributes name: "blah"
        @fluxor.destroy
      end
      should "only have a version for the name_updated event" do
        assert_equal 1, @fluxor.versions.length
        assert_equal "name_updated", @fluxor.versions.last.event
      end
    end
    context "on destroy" do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:destroy]
        END
        @fluxor = Fluxor.create.tap { |model| model.paper_trail_event = "destroyed" }
        @fluxor.update_attributes name: "blah"
        @fluxor.destroy
      end
      should "only have a version for the destroy event" do
        assert_equal 1, @fluxor.versions.length
        assert_equal "destroyed", @fluxor.versions.last.event
      end
    end
  end

  context "`PaperTrail::Config.version_limit` set" do
    setup do
      PaperTrail.config.version_limit = 2
      @widget = Widget.create! name: "Henry"
      6.times { @widget.update_attribute(:name, FFaker::Lorem.word) }
    end

    teardown { PaperTrail.config.version_limit = nil }

    should "limit the number of versions to 3 (2 plus the created at event)" do
      assert_equal "create", @widget.versions.first.event
      assert_equal 3, @widget.versions.size
    end
  end
end
