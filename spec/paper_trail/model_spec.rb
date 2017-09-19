require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
  context "A new record" do
    before { @widget = Widget.new }

    it "not have any previous versions" do
      expect(@widget.versions).to(eq([]))
    end

    it "be live" do
      expect(@widget.paper_trail.live?).to(eq(true))
    end

    context "which is then created" do
      before do
        @widget.update_attributes(name: "Henry", created_at: (Time.now - 1.day))
      end

      it "have one previous version" do
        expect(@widget.versions.length).to(eq(1))
      end

      it "be nil in its previous version" do
        expect(@widget.versions.first.object).to(be_nil)
        expect(@widget.versions.first.reify).to(be_nil)
      end

      it "record the correct event" do
        expect(@widget.versions.first.event).to(match(/create/i))
      end

      it "be live" do
        expect(@widget.paper_trail.live?).to(eq(true))
      end

      it "use the widget `updated_at` as the version's `created_at`" do
        expect(@widget.versions.first.created_at.to_i).to(eq(@widget.updated_at.to_i))
      end

      describe "#changeset" do
        it "has expected values" do
          changeset = @widget.versions.last.changeset
          expect(changeset["name"]).to eq([nil, "Henry"])
          expect(changeset["id"]).to eq([nil, @widget.id])
          # When comparing timestamps, round off to the nearest second, because
          # mysql doesn't do fractional seconds.
          expect(changeset["created_at"][0]).to be_nil
          expect(changeset["created_at"][1].to_i).to eq(@widget.created_at.to_i)
          expect(changeset["updated_at"][0]).to be_nil
          expect(changeset["updated_at"][1].to_i).to eq(@widget.updated_at.to_i)
        end
      end

      context "and then updated without any changes" do
        before { @widget.touch }

        it "not have a new version" do
          expect(@widget.versions.length).to(eq(1))
        end
      end

      context "and then updated with changes" do
        before { @widget.update_attributes(name: "Harry") }

        it "have two previous versions" do
          expect(@widget.versions.length).to(eq(2))
        end

        it "be available in its previous version" do
          expect(@widget.name).to(eq("Harry"))
          expect(@widget.versions.last.object).not_to(be_nil)
          widget = @widget.versions.last.reify
          expect(widget.name).to(eq("Henry"))
          expect(@widget.name).to(eq("Harry"))
        end

        it "have the same ID in its previous version" do
          expect(@widget.versions.last.reify.id).to(eq(@widget.id))
        end

        it "record the correct event" do
          expect(@widget.versions.last.event).to(match(/update/i))
        end

        it "have versions that are not live" do
          @widget.versions.map(&:reify).compact.each do |v|
            expect(v.paper_trail).not_to be_live
          end
        end

        it "have stored changes" do
          last_obj_changes = @widget.versions.last.object_changes
          actual = PaperTrail.serializer.load(last_obj_changes).reject do |k, _v|
            (k.to_sym == :updated_at)
          end
          expect(actual).to(eq("name" => %w[Henry Harry]))
          actual = @widget.versions.last.changeset.reject { |k, _v| (k.to_sym == :updated_at) }
          expect(actual).to(eq("name" => %w[Henry Harry]))
        end

        it "return changes with indifferent access" do
          expect(@widget.versions.last.changeset[:name]).to(eq(%w[Henry Harry]))
          expect(@widget.versions.last.changeset["name"]).to(eq(%w[Henry Harry]))
        end

        context "and has one associated object" do
          before { @wotsit = @widget.create_wotsit name: "John" }

          it "not copy the has_one association by default when reifying" do
            reified_widget = @widget.versions.last.reify
            expect(reified_widget.wotsit).to(eq(@wotsit))
            expect(@widget.reload.wotsit).to(eq(@wotsit))
          end

          it "copy the has_one association when reifying with :has_one => true" do
            reified_widget = @widget.versions.last.reify(has_one: true)
            expect(reified_widget.wotsit).to(be_nil)
            expect(@widget.reload.wotsit).to(eq(@wotsit))
          end
        end

        context "and has many associated objects" do
          before do
            @f0 = @widget.fluxors.create(name: "f-zero")
            @f1 = @widget.fluxors.create(name: "f-one")
            @reified_widget = @widget.versions.last.reify
          end

          it "copy the has_many associations when reifying" do
            expect(@reified_widget.fluxors.length).to(eq(@widget.fluxors.length))
            expect(@reified_widget.fluxors).to match_array(@widget.fluxors)
            expect(@reified_widget.versions.length).to(eq(@widget.versions.length))
            expect(@reified_widget.versions).to match_array(@widget.versions)
          end
        end

        context "and has many associated polymorphic objects" do
          before do
            @f0 = @widget.whatchamajiggers.create(name: "f-zero")
            @f1 = @widget.whatchamajiggers.create(name: "f-zero")
            @reified_widget = @widget.versions.last.reify
          end

          it "copy the has_many associations when reifying" do
            expect(@reified_widget.whatchamajiggers.length).to eq(@widget.whatchamajiggers.length)
            expect(@reified_widget.whatchamajiggers).to match_array(@widget.whatchamajiggers)
            expect(@reified_widget.versions.length).to(eq(@widget.versions.length))
            expect(@reified_widget.versions).to match_array(@widget.versions)
          end
        end

        context "polymorphic objects by themselves" do
          before { @widget = Whatchamajigger.new(name: "f-zero") }

          it "not fail with a nil pointer on the polymorphic association" do
            @widget.save!
          end
        end

        context "and then destroyed" do
          before do
            @fluxor = @widget.fluxors.create(name: "flux")
            @widget.destroy
            @reified_widget = PaperTrail::Version.last.reify
          end

          it "record the correct event" do
            expect(PaperTrail::Version.last.event).to(match(/destroy/i))
          end

          it "have three previous versions" do
            expect(PaperTrail::Version.with_item_keys("Widget", @widget.id).length).to(eq(3))
          end

          describe "#attributes" do
            it "returns the expected attributes for the reified widget" do
              expect(@reified_widget.id).to(eq(@widget.id))
              expected = @widget.attributes
              actual = @reified_widget.attributes
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
              expect(expected["created_at"].to_i).to eq(actual["created_at"].to_i)
              expect(expected["updated_at"].to_i).to eq(actual["updated_at"].to_i)
            end
          end

          it "be re-creatable from its previous version" do
            expect(@reified_widget.save).to(be_truthy)
          end

          it "restore its associations on its previous version" do
            @reified_widget.save
            expect(@reified_widget.fluxors.length).to(eq(1))
          end

          it "have nil item for last version" do
            expect(@widget.versions.last.item).to(be_nil)
          end

          it "not have changes" do
            expect(@widget.versions.last.changeset).to(eq({}))
          end
        end
      end
    end
  end

  context "A record's papertrail" do
    before do
      @date_time = DateTime.now.utc
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
        Widget.paper_trail.disable
        @count = @widget.versions.length
      end

      after { Widget.paper_trail.enable }

      context "when updated" do
        before { @widget.update_attributes(name: "Beeblebrox") }

        it "not add to its trail" do
          expect(@widget.versions.length).to(eq(@count))
        end
      end

      context "when destroyed \"without versioning\"" do
        it "leave paper trail off after call" do
          @widget.paper_trail.without_versioning(:destroy)
          expect(Widget.paper_trail.enabled?).to(eq(false))
        end
      end

      context "and then its paper trail turned on" do
        before { Widget.paper_trail.enable }

        context "when updated" do
          before { @widget.update_attributes(name: "Ford") }

          it "add to its trail" do
            expect(@widget.versions.length).to(eq((@count + 1)))
          end
        end

        context "when updated \"without versioning\"" do
          before do
            @widget.paper_trail.without_versioning do
              @widget.update_attributes(name: "Ford")
            end
            @widget.paper_trail.without_versioning do |w|
              w.update_attributes(name: "Nixon")
            end
          end

          it "not create new version" do
            expect(@widget.versions.length).to(eq(@count))
          end

          it "enable paper trail after call" do
            expect(Widget.paper_trail.enabled?).to(eq(true))
          end
        end

        context "when receiving a method name as an argument" do
          before { @widget.paper_trail.without_versioning(:touch_with_version) }

          it "not create new version" do
            expect(@widget.versions.length).to(eq(@count))
          end

          it "enable paper trail after call" do
            expect(Widget.paper_trail.enabled?).to(eq(true))
          end
        end
      end
    end
  end

  context "A papertrail with somebody making changes" do
    before { @widget = Widget.new(name: "Fidget") }

    context "when a record is created" do
      before do
        PaperTrail.whodunnit = "Alice"
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
          PaperTrail.whodunnit = "Bob"
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
            PaperTrail.whodunnit = "Charlie"
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
      PaperTrail.whodunnit = "Ben"
      @foo.update_attribute(:name, "Geoffrey")
      expect(@foo.paper_trail.originator).to(eq(PaperTrail.whodunnit))
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

  context "When an attribute has a custom serializer" do
    before { @person = Person.new(time_zone: "Samoa") }

    it "be an instance of ActiveSupport::TimeZone" do
      expect(@person.time_zone.class).to(eq(ActiveSupport::TimeZone))
    end

    context "when the model is saved" do
      before do
        @changes_before_save = @person.changes.dup
        @person.save!
      end

      it "version.object_changes should store long serialization of TimeZone object" do
        len = @person.versions.last.object_changes.length
        expect((len < 105)).to(be_truthy)
      end

      it "version.object_changes attribute should have stored the value from serializer" do
        as_stored_in_version = HashWithIndifferentAccess[
          YAML.load(@person.versions.last.object_changes)
        ]
        expect(as_stored_in_version[:time_zone]).to(eq([nil, "Samoa"]))
        serialized_value = Person::TimeZoneSerializer.dump(@person.time_zone)
        expect(as_stored_in_version[:time_zone].last).to(eq(serialized_value))
      end

      it "version.changeset should convert attribute to original, unserialized value" do
        unserialized_value = Person::TimeZoneSerializer.load(@person.time_zone)
        expect(@person.versions.last.changeset[:time_zone].last).to(eq(unserialized_value))
      end

      it "record.changes (before save) returns the original, unserialized values" do
        expect(
          @changes_before_save[:time_zone].map(&:class)
        ).to(eq([NilClass, ActiveSupport::TimeZone]))
      end

      it "version.changeset should be the same as record.changes was before the save" do
        actual = @person.versions.last.changeset.delete_if { |k, _v| (k.to_sym == :id) }
        expect(actual).to(eq(@changes_before_save))
        actual = @person.versions.last.changeset[:time_zone].map(&:class)
        expect(actual).to(eq([NilClass, ActiveSupport::TimeZone]))
      end

      context "when that attribute is updated" do
        before do
          @attribute_value_before_change = @person.time_zone
          @person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
          @changes_before_save = @person.changes.dup
          @person.save!
        end

        it "object should not store long serialization of TimeZone object" do
          len = @person.versions.last.object.length
          expect((len < 105)).to(be_truthy)
        end

        it "object_changes should not store long serialization of TimeZone object" do
          max_len = ActiveRecord::VERSION::MAJOR < 4 ? 105 : 118
          len = @person.versions.last.object_changes.length
          expect((len < max_len)).to(be_truthy)
        end

        it "version.object attribute should have stored value from serializer" do
          as_stored_in_version = HashWithIndifferentAccess[
            YAML.load(@person.versions.last.object)
          ]
          expect(as_stored_in_version[:time_zone]).to(eq("Samoa"))
          serialized_value = Person::TimeZoneSerializer.dump(@attribute_value_before_change)
          expect(as_stored_in_version[:time_zone]).to(eq(serialized_value))
        end

        it "version.object_changes attribute should have stored value from serializer" do
          as_stored_in_version = HashWithIndifferentAccess[
            YAML.load(@person.versions.last.object_changes)
          ]
          expect(as_stored_in_version[:time_zone]).to(eq(["Samoa", "Pacific Time (US & Canada)"]))
          serialized_value = Person::TimeZoneSerializer.dump(@person.time_zone)
          expect(as_stored_in_version[:time_zone].last).to(eq(serialized_value))
        end

        it "version.reify should convert attribute to original, unserialized value" do
          unserialized_value = Person::TimeZoneSerializer.load(@attribute_value_before_change)
          expect(@person.versions.last.reify.time_zone).to(eq(unserialized_value))
        end

        it "version.changeset should convert attribute to original, unserialized value" do
          unserialized_value = Person::TimeZoneSerializer.load(@person.time_zone)
          expect(@person.versions.last.changeset[:time_zone].last).to(eq(unserialized_value))
        end

        it "record.changes (before save) returns the original, unserialized values" do
          expect(
            @changes_before_save[:time_zone].map(&:class)
          ).to(eq([ActiveSupport::TimeZone, ActiveSupport::TimeZone]))
        end

        it "version.changeset should be the same as record.changes was before the save" do
          expect(@person.versions.last.changeset).to(eq(@changes_before_save))
          expect(
            @person.versions.last.changeset[:time_zone].map(&:class)
          ).to(eq([ActiveSupport::TimeZone, ActiveSupport::TimeZone]))
        end
      end
    end
  end

  context "A new model instance which uses a custom PaperTrail::Version class" do
    before { @post = Post.new }

    context "which is then saved" do
      before { @post.save }

      it "change the number of post versions" do
        expect(PostVersion.count).to(eq(1))
      end

      it "not change the number of versions" do
        expect(PaperTrail::Version.count).to(eq(0))
      end
    end
  end

  context "An existing model instance which uses a custom PaperTrail::Version class" do
    before { @post = Post.create }

    it "have one post version" do
      expect(PostVersion.count).to(eq(1))
    end

    context "on the first version" do
      before { @version = @post.versions.first }

      it "have the correct index" do
        expect(@version.index).to(eq(0))
      end
    end

    it "have versions of the custom class" do
      expect(@post.versions.first.class.name).to(eq("PostVersion"))
    end

    context "which is modified" do
      before { @post.update_attributes(content: "Some new content") }

      it "change the number of post versions" do
        expect(PostVersion.count).to(eq(2))
      end

      it "not change the number of versions" do
        expect(PaperTrail::Version.count).to(eq(0))
      end

      it "not have stored changes when object_changes column doesn't exist" do
        expect(@post.versions.last.changeset).to(be_nil)
      end
    end
  end

  context "An overwritten default accessor" do
    before do
      @song = Song.create(length: 4)
      @song.update_attributes(length: 5)
    end

    it "return \"overwritten\" value on live instance" do
      expect(@song.length).to(eq(5))
    end

    it "return \"overwritten\" value on reified instance" do
      expect(@song.versions.last.reify.length).to(eq(4))
    end

    context "Has a virtual attribute injected into the ActiveModel::Dirty changes" do
      before do
        @song.name = "Good Vibrations"
        @song.save
        @song.name = "Yellow Submarine"
      end

      it "return persist the changes on the live instance properly" do
        expect(@song.name).to(eq("Yellow Submarine"))
      end

      it "return \"overwritten\" virtual attribute on the reified instance" do
        expect(@song.versions.last.reify.name).to(eq("Good Vibrations"))
      end
    end
  end

  context "An unsaved record" do
    before do
      @widget = Widget.new
      @widget.destroy
    end

    it "not have a version created on destroy" do
      expect(@widget.versions.empty?).to(eq(true))
    end
  end
end
