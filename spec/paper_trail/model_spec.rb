# frozen_string_literal: true

require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
  context "a new record" do
    it "not have any previous versions" do
      expect(Widget.new.versions).to(eq([]))
    end

    it "be live" do
      expect(Widget.new.paper_trail.live?).to(eq(true))
    end
  end

  context "a persisted record" do
    it "have one previous version" do
      widget = Widget.create(name: "Henry", created_at: (Time.now - 1.day))
      expect(widget.versions.length).to(eq(1))
    end

    it "be nil in its previous version" do
      widget = Widget.create(name: "Henry")
      expect(widget.versions.first.object).to(be_nil)
      expect(widget.versions.first.reify).to(be_nil)
    end

    it "record the correct event" do
      widget = Widget.create(name: "Henry")
      expect(widget.versions.first.event).to(match(/create/i))
    end

    it "be live" do
      widget = Widget.create(name: "Henry")
      expect(widget.paper_trail.live?).to(eq(true))
    end

    it "use the widget `updated_at` as the version's `created_at`" do
      widget = Widget.create(name: "Henry")
      expect(widget.versions.first.created_at.to_i).to(eq(widget.updated_at.to_i))
    end

    describe "#changeset" do
      it "has expected values" do
        widget = Widget.create(name: "Henry")
        changeset = widget.versions.last.changeset
        expect(changeset["name"]).to eq([nil, "Henry"])
        expect(changeset["id"]).to eq([nil, widget.id])
        # When comparing timestamps, round off to the nearest second, because
        # mysql doesn't do fractional seconds.
        expect(changeset["created_at"][0]).to be_nil
        expect(changeset["created_at"][1].to_i).to eq(widget.created_at.to_i)
        expect(changeset["updated_at"][0]).to be_nil
        expect(changeset["updated_at"][1].to_i).to eq(widget.updated_at.to_i)
      end

      context "custom object_changes_adapter" do
        after do
          PaperTrail.config.object_changes_adapter = nil
        end

        it "calls the adapter's load_changeset method" do
          widget = Widget.create(name: "Henry")
          adapter = instance_spy("CustomObjectChangesAdapter")
          PaperTrail.config.object_changes_adapter = adapter
          allow(adapter).to(
            receive(:load_changeset).with(widget.versions.last).and_return(a: "b", c: "d")
          )
          changeset = widget.versions.last.changeset
          expect(changeset[:a]).to eq("b")
          expect(changeset[:c]).to eq("d")
          expect(adapter).to have_received(:load_changeset)
        end
      end
    end

    context "and then updated without any changes" do
      it "to have two previous versions" do
        widget = Widget.create(name: "Henry")
        widget.touch
        expect(widget.versions.length).to eq(2)
      end
    end

    context "and then updated with changes" do
      it "have three previous versions" do
        widget = Widget.create(name: "Henry")
        widget.update_attributes(name: "Harry")
        expect(widget.versions.length).to(eq(2))
      end

      it "be available in its previous version" do
        widget = Widget.create(name: "Henry")
        widget.update_attributes(name: "Harry")
        expect(widget.name).to(eq("Harry"))
        expect(widget.versions.last.object).not_to(be_nil)
        reified_widget = widget.versions.last.reify
        expect(reified_widget.name).to(eq("Henry"))
        expect(widget.name).to(eq("Harry"))
      end

      it "have the same ID in its previous version" do
        widget = Widget.create(name: "Henry")
        widget.update_attributes(name: "Harry")
        expect(widget.versions.last.reify.id).to(eq(widget.id))
      end

      it "record the correct event" do
        widget = Widget.create(name: "Henry")
        widget.update_attributes(name: "Harry")
        expect(widget.versions.last.event).to(match(/update/i))
      end

      it "have versions that are not live" do
        widget = Widget.create(name: "Henry")
        widget.update_attributes(name: "Harry")
        widget.versions.map(&:reify).compact.each do |v|
          expect(v.paper_trail).not_to be_live
        end
      end

      it "have stored changes" do
        widget = Widget.create(name: "Henry")
        widget.update_attributes(name: "Harry")
        last_obj_changes = widget.versions.last.object_changes
        actual = PaperTrail.serializer.load(last_obj_changes).reject do |k, _v|
          (k.to_sym == :updated_at)
        end
        expect(actual).to(eq("name" => %w[Henry Harry]))
        actual = widget.versions.last.changeset.reject { |k, _v| (k.to_sym == :updated_at) }
        expect(actual).to(eq("name" => %w[Henry Harry]))
      end

      it "return changes with indifferent access" do
        widget = Widget.create(name: "Henry")
        widget.update_attributes(name: "Harry")
        expect(widget.versions.last.changeset[:name]).to(eq(%w[Henry Harry]))
        expect(widget.versions.last.changeset["name"]).to(eq(%w[Henry Harry]))
      end

      context "and has one associated object" do
        it "not copy the has_one association by default when reifying" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          wotsit = widget.create_wotsit name: "John"
          reified_widget = widget.versions.last.reify
          expect(reified_widget.wotsit).to eq(wotsit)
          expect(widget.reload.wotsit).to eq(wotsit)
        end

        it "copy the has_one association when reifying with :has_one => true" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          wotsit = widget.create_wotsit name: "John"
          reified_widget = widget.versions.last.reify(has_one: true)
          expect(reified_widget.wotsit).to(be_nil)
          expect(widget.reload.wotsit).to eq(wotsit)
        end
      end

      context "and has many associated objects" do
        it "copy the has_many associations when reifying" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.fluxors.create(name: "f-zero")
          widget.fluxors.create(name: "f-one")
          reified_widget = widget.versions.last.reify
          expect(reified_widget.fluxors.length).to(eq(widget.fluxors.length))
          expect(reified_widget.fluxors).to match_array(widget.fluxors)
          expect(reified_widget.versions.length).to(eq(widget.versions.length))
          expect(reified_widget.versions).to match_array(widget.versions)
        end
      end

      context "and has many associated polymorphic objects" do
        it "copy the has_many associations when reifying" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.whatchamajiggers.create(name: "f-zero")
          widget.whatchamajiggers.create(name: "f-zero")
          reified_widget = widget.versions.last.reify
          expect(reified_widget.whatchamajiggers.length).to eq(widget.whatchamajiggers.length)
          expect(reified_widget.whatchamajiggers).to match_array(widget.whatchamajiggers)
          expect(reified_widget.versions.length).to(eq(widget.versions.length))
          expect(reified_widget.versions).to match_array(widget.versions)
        end
      end

      context "polymorphic objects by themselves" do
        it "not fail with a nil pointer on the polymorphic association" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget = Whatchamajigger.new(name: "f-zero")
          widget.save!
        end
      end

      context "and then destroyed" do
        it "record the correct event" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.destroy
          expect(PaperTrail::Version.last.event).to(match(/destroy/i))
        end

        it "have three previous versions" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.destroy
          expect(PaperTrail::Version.with_item_keys("Widget", widget.id).length).to(eq(3))
        end

        describe "#attributes" do
          it "returns the expected attributes for the reified widget" do
            widget = Widget.create(name: "Henry")
            widget.update_attributes(name: "Harry")
            widget.destroy
            reified_widget = PaperTrail::Version.last.reify
            expect(reified_widget.id).to eq(widget.id)
            expected = widget.attributes
            actual = reified_widget.attributes
            expect(expected["id"]).to eq(actual["id"])
            expect(expected["name"]).to eq(actual["name"])
            expect(expected["a_text"]).to eq(actual["a_text"])
            expect(expected["an_integer"]).to eq(actual["an_integer"])
            expect(expected["a_float"]).to eq(actual["a_float"])
            expect(expected["a_decimal"]).to eq(actual["a_decimal"])
            expect(expected["a_datetime"]).to eq(actual["a_datetime"])
            expect(expected["a_time"]).to eq(actual["a_time"])
            expect(expected["a_date"]).to eq(actual["a_date"])
            expect(expected["a_boolean"]).to eq(actual["a_boolean"])
            expect(expected["type"]).to eq(actual["type"])

            # We are using `to_i` to truncate to the nearest second, but isn't
            # there still a chance of this failing intermittently if
            # ___ and ___ occured more than 0.5s apart?
            expect(expected["created_at"].to_i).to eq(actual["created_at"].to_i)
            expect(expected["updated_at"].to_i).to eq(actual["updated_at"].to_i)
          end
        end

        it "be re-creatable from its previous version" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.destroy
          reified_widget = PaperTrail::Version.last.reify
          expect(reified_widget.save).to(be_truthy)
        end

        it "restore its associations on its previous version" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.fluxors.create(name: "flux")
          widget.destroy
          reified_widget = PaperTrail::Version.last.reify
          reified_widget.save
          expect(reified_widget.fluxors.length).to(eq(1))
        end

        it "have nil item for last version" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.destroy
          expect(widget.versions.last.item).to be_nil
        end

        it "not have changes" do
          widget = Widget.create(name: "Henry")
          widget.update_attributes(name: "Harry")
          widget.destroy
          expect(widget.versions.last.changeset).to eq({})
        end
      end
    end
  end

  # rubocop:disable RSpec/InstanceVariable
  context "a record's papertrail" do
    before do
      @date_time = Time.now
      @time = Time.now
      @date = Date.new(2009, 5, 29)
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

    it "handle strings" do
      expect(@previous.name).to(eq("Warble"))
    end

    it "handle text" do
      expect(@previous.a_text).to(eq("The quick brown fox"))
    end

    it "handle integers" do
      expect(@previous.an_integer).to(eq(42))
    end

    it "handle floats" do
      assert_in_delta(153.01, @previous.a_float, 0.001)
    end

    it "handle decimals" do
      assert_in_delta(2.7183, @previous.a_decimal, 0.0001)
    end

    it "handle datetimes" do
      expect(@previous.a_datetime.to_time.utc.to_i).to(eq(@date_time.to_time.utc.to_i))
    end

    it "handle times" do
      expect(@previous.a_time.utc.to_i).to(eq(@time.utc.to_i))
    end

    it "handle dates" do
      expect(@previous.a_date).to(eq(@date))
    end

    it "handle booleans" do
      expect(@previous.a_boolean).to(be_truthy)
    end

    context "after a column is removed from the record's schema" do
      before { @last = @widget.versions.last }

      it "reify previous version" do
        assert_kind_of(Widget, @last.reify)
      end

      it "restore all forward-compatible attributes" do
        expect(@last.reify.name).to(eq("Warble"))
        expect(@last.reify.a_text).to(eq("The quick brown fox"))
        expect(@last.reify.an_integer).to(eq(42))
        assert_in_delta(153.01, @last.reify.a_float, 0.001)
        assert_in_delta(2.7183, @last.reify.a_decimal, 0.0001)
        expect(@last.reify.a_datetime.to_time.utc.to_i).to(eq(@date_time.to_time.utc.to_i))
        expect(@last.reify.a_time.utc.to_i).to(eq(@time.utc.to_i))
        expect(@last.reify.a_date).to(eq(@date))
        expect(@last.reify.a_boolean).to(be_truthy)
      end
    end
  end

  context "A record" do
    before { @widget = Widget.create(name: "Zaphod") }

    context "with PaperTrail globally disabled" do
      before do
        PaperTrail.enabled = false
        @count = @widget.versions.length
      end

      after { PaperTrail.enabled = true }

      context "when updated" do
        before { @widget.update_attributes(name: "Beeblebrox") }

        it "not add to its trail" do
          expect(@widget.versions.length).to(eq(@count))
        end
      end
    end

    context "with its paper trail turned off" do
      before do
        PaperTrail.request.disable_model(Widget)
        @count = @widget.versions.length
      end

      after do
        PaperTrail.request.enable_model(Widget)
      end

      context "when updated" do
        before { @widget.update_attributes(name: "Beeblebrox") }

        it "not add to its trail" do
          expect(@widget.versions.length).to(eq(@count))
        end
      end

      context "when destroyed \"without versioning\"" do
        it "leave paper trail off after call" do
          allow(::ActiveSupport::Deprecation).to receive(:warn)
          @widget.paper_trail.without_versioning(:destroy)
          expect(::PaperTrail.request.enabled_for_model?(Widget)).to eq(false)
          expect(::ActiveSupport::Deprecation).to have_received(:warn).once
        end
      end

      context "and then its paper trail turned on" do
        before do
          PaperTrail.request.enable_model(Widget)
        end

        context "when updated" do
          before { @widget.update_attributes(name: "Ford") }

          it "add to its trail" do
            expect(@widget.versions.length).to(eq((@count + 1)))
          end
        end

        context "when updated \"without versioning\"" do
          it "does not create new version" do
            allow(::ActiveSupport::Deprecation).to receive(:warn)
            @widget.paper_trail.without_versioning do
              @widget.update_attributes(name: "Ford")
            end
            @widget.paper_trail.without_versioning do |w|
              w.update_attributes(name: "Nixon")
            end
            expect(@widget.versions.length).to(eq(@count))
            expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
            expect(::ActiveSupport::Deprecation).to have_received(:warn).twice
          end
        end

        context "given a symbol, specifying a method name" do
          it "does not create a new version" do
            allow(::ActiveSupport::Deprecation).to receive(:warn)
            @widget.paper_trail.without_versioning(:touch)
            expect(::ActiveSupport::Deprecation).to have_received(:warn).once
            expect(@widget.versions.length).to(eq(@count))
            expect(::PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
          end
        end
      end
    end
  end

  context "A papertrail with somebody making changes" do
    before { @widget = Widget.new(name: "Fidget") }

    context "when a record is created" do
      before do
        PaperTrail.request.whodunnit = "Alice"
        @widget.save
        @version = @widget.versions.last
      end

      it "track who made the change" do
        expect(@version.whodunnit).to(eq("Alice"))
        expect(@version.paper_trail_originator).to(be_nil)
        expect(@version.terminator).to(eq("Alice"))
        expect(@widget.paper_trail.originator).to(eq("Alice"))
      end

      context "when a record is updated" do
        before do
          PaperTrail.request.whodunnit = "Bob"
          @widget.update_attributes(name: "Rivet")
          @version = @widget.versions.last
        end

        it "track who made the change" do
          expect(@version.whodunnit).to(eq("Bob"))
          expect(@version.paper_trail_originator).to(eq("Alice"))
          expect(@version.terminator).to(eq("Bob"))
          expect(@widget.paper_trail.originator).to(eq("Bob"))
        end

        context "when a record is destroyed" do
          before do
            PaperTrail.request.whodunnit = "Charlie"
            @widget.destroy
            @version = PaperTrail::Version.last
          end

          it "track who made the change" do
            expect(@version.whodunnit).to(eq("Charlie"))
            expect(@version.paper_trail_originator).to(eq("Bob"))
            expect(@version.terminator).to(eq("Charlie"))
            expect(@widget.paper_trail.originator).to(eq("Charlie"))
          end
        end
      end
    end
  end

  it "update_attributes! records timestamps" do
    wotsit = Wotsit.create!(name: "wotsit")
    wotsit.update_attributes!(name: "changed")
    reified = wotsit.versions.last.reify
    expect(reified.created_at).not_to(be_nil)
    expect(reified.updated_at).not_to(be_nil)
  end

  it "update_attributes! does not raise error" do
    wotsit = Wotsit.create!(name: "name1")
    expect { wotsit.update_attributes!(name: "name2") }.not_to(raise_error)
  end

  context "A subclass" do
    before do
      @foo = FooWidget.create
      @foo.update_attributes!(name: "Foo")
    end

    it "reify with the correct type" do
      if ActiveRecord::VERSION::MAJOR < 4
        assert_kind_of(FooWidget, @foo.versions.last.reify)
      end
      expect(PaperTrail::Version.last.previous).to(eq(@foo.versions.first))
      expect(PaperTrail::Version.last.next).to(be_nil)
    end

    it "returns the correct originator" do
      PaperTrail.request.whodunnit = "Ben"
      @foo.update_attribute(:name, "Geoffrey")
      expect(@foo.paper_trail.originator).to(eq(PaperTrail.request.whodunnit))
    end

    context "when destroyed" do
      before { @foo.destroy }

      it "reify with the correct type" do
        assert_kind_of(FooWidget, @foo.versions.last.reify)
        expect(PaperTrail::Version.last.previous).to(eq(@foo.versions[1]))
        expect(PaperTrail::Version.last.next).to(be_nil)
      end
    end
  end

  context "An item with versions" do
    before do
      @widget = Widget.create(name: "Widget")
      @widget.update_attributes(name: "Fidget")
      @widget.update_attributes(name: "Digit")
    end

    context "which were created over time" do
      before do
        @created = 2.days.ago
        @first_update = 1.day.ago
        @second_update = 1.hour.ago
        @widget.versions[0].update_attributes(created_at: @created)
        @widget.versions[1].update_attributes(created_at: @first_update)
        @widget.versions[2].update_attributes(created_at: @second_update)
        @widget.update_attribute(:updated_at, @second_update)
      end

      it "return nil for version_at before it was created" do
        expect(@widget.paper_trail.version_at((@created - 1))).to(be_nil)
      end

      it "return how it looked when created for version_at its creation" do
        expect(@widget.paper_trail.version_at(@created).name).to(eq("Widget"))
      end

      it "return how it looked before its first update" do
        expect(@widget.paper_trail.version_at((@first_update - 1)).name).to(eq("Widget"))
      end

      it "return how it looked after its first update" do
        expect(@widget.paper_trail.version_at(@first_update).name).to(eq("Fidget"))
      end

      it "return how it looked before its second update" do
        expect(@widget.paper_trail.version_at((@second_update - 1)).name).to(eq("Fidget"))
      end

      it "return how it looked after its second update" do
        expect(@widget.paper_trail.version_at(@second_update).name).to(eq("Digit"))
      end

      it "return the current object for version_at after latest update" do
        expect(@widget.paper_trail.version_at(1.day.from_now).name).to(eq("Digit"))
      end

      context "passing in a string representation of a timestamp" do
        it "still return a widget when appropriate" do
          expect(
            @widget.paper_trail.version_at((@created + 1.second).to_s).name
          ).to(eq("Widget"))
          expect(
            @widget.paper_trail.version_at((@first_update + 1.second).to_s).name
          ).to(eq("Fidget"))
          expect(
            @widget.paper_trail.version_at((@second_update + 1.second).to_s).name
          ).to(eq("Digit"))
        end
      end
    end

    context ".versions_between" do
      before do
        @created = 30.days.ago
        @first_update = 15.days.ago
        @second_update = 1.day.ago
        @widget.versions[0].update_attributes(created_at: @created)
        @widget.versions[1].update_attributes(created_at: @first_update)
        @widget.versions[2].update_attributes(created_at: @second_update)
        @widget.update_attribute(:updated_at, @second_update)
      end

      it "return versions in the time period" do
        expect(
          @widget.paper_trail.versions_between(20.days.ago, 10.days.ago).map(&:name)
        ).to(eq(["Fidget"]))
        expect(
          @widget.paper_trail.versions_between(45.days.ago, 10.days.ago).map(&:name)
        ).to(eq(%w[Widget Fidget]))
        expect(
          @widget.paper_trail.versions_between(16.days.ago, 1.minute.ago).map(&:name)
        ).to(eq(%w[Fidget Digit Digit]))
        expect(
          @widget.paper_trail.versions_between(60.days.ago, 45.days.ago).map(&:name)
        ).to(eq([]))
      end
    end

    context "on the first version" do
      before { @version = @widget.versions.first }

      it "have a nil previous version" do
        expect(@version.previous).to(be_nil)
      end

      it "return the next version" do
        expect(@version.next).to(eq(@widget.versions[1]))
      end

      it "return the correct index" do
        expect(@version.index).to(eq(0))
      end
    end

    context "on the last version" do
      before { @version = @widget.versions.last }

      it "return the previous version" do
        expect(@version.previous).to(eq(@widget.versions[(@widget.versions.length - 2)]))
      end

      it "have a nil next version" do
        expect(@version.next).to(be_nil)
      end

      it "return the correct index" do
        expect(@version.index).to(eq((@widget.versions.length - 1)))
      end
    end
  end

  context "An item" do
    before do
      @initial_title = "Foobar"
      @article = Article.new(title: @initial_title)
    end

    context "which is created" do
      before { @article.save }

      it "store fixed meta data" do
        expect(@article.versions.last.answer).to(eq(42))
      end

      it "store dynamic meta data which is independent of the item" do
        expect(@article.versions.last.question).to(eq("31 + 11 = 42"))
      end

      it "store dynamic meta data which depends on the item" do
        expect(@article.versions.last.article_id).to(eq(@article.id))
      end

      it "store dynamic meta data based on a method of the item" do
        expect(@article.versions.last.action).to(eq(@article.action_data_provider_method))
      end

      it "store dynamic meta data based on an attribute of the item at creation" do
        expect(@article.versions.last.title).to(eq(@initial_title))
      end

      context "and updated" do
        before do
          @article.update_attributes!(content: "Better text.", title: "Rhubarb")
        end

        it "store fixed meta data" do
          expect(@article.versions.last.answer).to(eq(42))
        end

        it "store dynamic meta data which is independent of the item" do
          expect(@article.versions.last.question).to(eq("31 + 11 = 42"))
        end

        it "store dynamic meta data which depends on the item" do
          expect(@article.versions.last.article_id).to(eq(@article.id))
        end

        it "store dynamic meta data based on an attribute of the item prior to the update" do
          expect(@article.versions.last.title).to(eq(@initial_title))
        end
      end

      context "and destroyed" do
        before { @article.destroy }

        it "store fixed metadata" do
          expect(@article.versions.last.answer).to(eq(42))
        end

        it "store dynamic metadata which is independent of the item" do
          expect(@article.versions.last.question).to(eq("31 + 11 = 42"))
        end

        it "store dynamic metadata which depends on the item" do
          expect(@article.versions.last.article_id).to(eq(@article.id))
        end

        it "store dynamic metadata based on attribute of item prior to destruction" do
          expect(@article.versions.last.title).to(eq(@initial_title))
        end
      end
    end
  end

  context "A reified item" do
    before do
      widget = Widget.create(name: "Bob")
      %w[Tom Dick Jane].each do |name|
        widget.update_attributes(name: name)
      end
      @version = widget.versions.last
      @widget = @version.reify
    end

    it "know which version it came from" do
      expect(@widget.version).to(eq(@version))
    end

    it "return its previous self" do
      expect(@widget.paper_trail.previous_version).to(eq(@widget.versions[-2].reify))
    end
  end

  context "A non-reified item" do
    before { @widget = Widget.new }

    it "not have a previous version" do
      expect(@widget.paper_trail.previous_version).to(be_nil)
    end

    it "not have a next version" do
      expect(@widget.paper_trail.next_version).to(be_nil)
    end

    context "with versions" do
      before do
        @widget.save
        %w[Tom Dick Jane].each do |name|
          @widget.update_attributes(name: name)
        end
      end

      it "have a previous version" do
        expect(@widget.paper_trail.previous_version.name).to(eq(@widget.versions.last.reify.name))
      end

      it "not have a next version" do
        expect(@widget.paper_trail.next_version).to(be_nil)
      end
    end
  end

  context "A reified item" do
    before do
      @widget = Widget.create(name: "Bob")
      %w[Tom Dick Jane].each do |name|
        @widget.update_attributes(name: name)
      end
      @second_widget = @widget.versions[1].reify
      @last_widget = @widget.versions.last.reify
    end

    it "have a previous version" do
      expect(@second_widget.paper_trail.previous_version).to(be_nil)
      expect(@last_widget.paper_trail.previous_version.name).to(eq(@widget.versions[-2].reify.name))
    end

    it "have a next version" do
      expect(@second_widget.paper_trail.next_version.name).to(eq(@widget.versions[2].reify.name))
      expect(@widget.name).to(eq(@last_widget.paper_trail.next_version.name))
    end
  end

  context ":has_many :through" do
    before do
      @book = Book.create(title: "War and Peace")
      @dostoyevsky = Person.create(name: "Dostoyevsky")
      @solzhenitsyn = Person.create(name: "Solzhenitsyn")
    end

    it "store version on source <<" do
      count = PaperTrail::Version.count
      (@book.authors << @dostoyevsky)
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(@book.authorships.first.versions.first).to(eq(PaperTrail::Version.last))
    end

    it "store version on source create" do
      count = PaperTrail::Version.count
      @book.authors.create(name: "Tolstoy")
      expect((PaperTrail::Version.count - count)).to(eq(2))
      expect(
        [PaperTrail::Version.order(:id).to_a[-2].item, PaperTrail::Version.last.item]
      ).to match_array([Person.last, Authorship.last])
    end

    it "store version on join destroy" do
      (@book.authors << @dostoyevsky)
      count = PaperTrail::Version.count
      @book.authorships.reload.last.destroy
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(PaperTrail::Version.last.reify.book).to(eq(@book))
      expect(PaperTrail::Version.last.reify.author).to(eq(@dostoyevsky))
    end

    it "store version on join clear" do
      (@book.authors << @dostoyevsky)
      count = PaperTrail::Version.count
      @book.authorships.reload.destroy_all
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(PaperTrail::Version.last.reify.book).to(eq(@book))
      expect(PaperTrail::Version.last.reify.author).to(eq(@dostoyevsky))
    end
  end
  # rubocop:enable RSpec/InstanceVariable

  context "the default accessor, length=, is overwritten" do
    it "returns overwritten value on reified instance" do
      song = Song.create(length: 4)
      song.update_attributes(length: 5)
      expect(song.length).to(eq(5))
      expect(song.versions.last.reify.length).to(eq(4))
    end
  end

  context "song name is a virtual attribute (no such db column)" do
    it "returns overwritten virtual attribute on the reified instance" do
      song = Song.create(length: 4)
      song.update_attributes(length: 5)
      song.name = "Good Vibrations"
      song.save
      song.name = "Yellow Submarine"
      expect(song.name).to(eq("Yellow Submarine"))
      expect(song.versions.last.reify.name).to(eq("Good Vibrations"))
    end
  end

  context "An unsaved record" do
    it "not have a version created on destroy" do
      widget = Widget.new
      widget.destroy
      expect(widget.versions.empty?).to(eq(true))
    end
  end

  context "without the object column" do
    # rubocop:disable RSpec/BeforeAfterAll
    before :all do
      ActiveRecord::Migration.remove_column :versions, :object
      PaperTrail::Version.reset_column_information
    end
    after :all do
      ActiveRecord::Migration.add_column :versions, :object, :text
      PaperTrail::Version.reset_column_information
    end
    # rubocop:enable RSpec/BeforeAfterAll

    it "versions are created" do
      song = Song.create length: 4
      version = song.versions.last.attributes
      expect(version).not_to include "object"
      expect(version["event"]).to eq "create"
      expect(version["object_changes"]).to start_with("---")

      song.update length: 5
      version = song.versions.last.attributes
      expect(version).not_to include "object"
      expect(version["event"]).to eq "update"
      expect(version["object_changes"]).to start_with("---")

      song.destroy
      version = song.versions.last.attributes
      expect(version).not_to include "object"
      expect(version["event"]).to eq "destroy"
      expect(version["object_changes"]).to eq nil
    end

    it "reify doesn't work" do
      song = Song.create length: 4
      song.update length: 5

      expect do
        song.versions.first.reify
      end.to raise_error "reify can't be called without an object column"
    end

    it "where_object doesn't work" do
      song = Song.create length: 4
      song.update length: 5

      expect do
        song.versions.where_object length: 4
      end.to raise_error "where_object can't be called without an object column"
    end
  end
end
