# frozen_string_literal: true

require "spec_helper"
require "support/performance_helpers"

RSpec.describe Widget, type: :model, versioning: true do
  describe "#changeset" do
    it "has expected values" do
      widget = described_class.create(name: "Henry")
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

    context "with custom object_changes_adapter" do
      after do
        PaperTrail.config.object_changes_adapter = nil
      end

      it "calls the adapter's load_changeset method" do
        widget = described_class.create(name: "Henry")
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

      it "defaults to the original behavior" do
        adapter = Class.new.new
        PaperTrail.config.object_changes_adapter = adapter
        widget = described_class.create(name: "Henry")
        changeset = widget.versions.last.changeset
        expect(changeset[:name]).to eq([nil, "Henry"])
      end
    end
  end

  context "with a new record" do
    it "not have any previous versions" do
      expect(described_class.new.versions).to(eq([]))
    end

    it "be live" do
      expect(described_class.new.paper_trail.live?).to(eq(true))
    end
  end

  context "with a persisted record" do
    it "have one previous version" do
      widget = described_class.create(name: "Henry", created_at: (Time.current - 1.day))
      expect(widget.versions.length).to(eq(1))
    end

    it "be nil in its previous version" do
      widget = described_class.create(name: "Henry")
      expect(widget.versions.first.object).to(be_nil)
      expect(widget.versions.first.reify).to(be_nil)
    end

    it "record the correct event" do
      widget = described_class.create(name: "Henry")
      expect(widget.versions.first.event).to(match(/create/i))
    end

    it "be live" do
      widget = described_class.create(name: "Henry")
      expect(widget.paper_trail.live?).to(eq(true))
    end

    it "use the widget `updated_at` as the version's `created_at`" do
      widget = described_class.create(name: "Henry")
      expect(widget.versions.first.created_at.to_i).to(eq(widget.updated_at.to_i))
    end

    context "when updated without any changes" do
      it "to have two previous versions" do
        widget = described_class.create(name: "Henry")
        widget.touch
        expect(widget.versions.length).to eq(2)
      end
    end

    context "when updated with changes" do
      it "have three previous versions" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        expect(widget.versions.length).to(eq(2))
      end

      it "be available in its previous version" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        expect(widget.name).to(eq("Harry"))
        expect(widget.versions.last.object).not_to(be_nil)
        reified_widget = widget.versions.last.reify
        expect(reified_widget.name).to(eq("Henry"))
        expect(widget.name).to(eq("Harry"))
      end

      it "have the same ID in its previous version" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        expect(widget.versions.last.reify.id).to(eq(widget.id))
      end

      it "record the correct event" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        expect(widget.versions.last.event).to(match(/update/i))
      end

      it "have versions that are not live" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.versions.map(&:reify).compact.each do |v|
          expect(v.paper_trail).not_to be_live
        end
      end

      it "have stored changes" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        last_obj_changes = widget.versions.last.object_changes
        actual = PaperTrail.serializer.load(last_obj_changes).reject do |k, _v|
          (k.to_sym == :updated_at)
        end
        expect(actual).to(eq("name" => %w[Henry Harry]))
        actual = widget.versions.last.changeset.reject { |k, _v| (k.to_sym == :updated_at) }
        expect(actual).to(eq("name" => %w[Henry Harry]))
      end

      it "return changes with indifferent access" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        expect(widget.versions.last.changeset[:name]).to(eq(%w[Henry Harry]))
        expect(widget.versions.last.changeset["name"]).to(eq(%w[Henry Harry]))
      end
    end

    context "when updated, and has one associated object" do
      it "not copy the has_one association by default when reifying" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        wotsit = widget.create_wotsit name: "John"
        reified_widget = widget.versions.last.reify
        expect(reified_widget.wotsit).to eq(wotsit)
        expect(widget.reload.wotsit).to eq(wotsit)
      end
    end

    context "when updated, and has many associated objects" do
      it "copy the has_many associations when reifying" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.fluxors.create(name: "f-zero")
        widget.fluxors.create(name: "f-one")
        reified_widget = widget.versions.last.reify
        expect(reified_widget.fluxors.length).to(eq(widget.fluxors.length))
        expect(reified_widget.fluxors).to match_array(widget.fluxors)
        expect(reified_widget.versions.length).to(eq(widget.versions.length))
        expect(reified_widget.versions).to match_array(widget.versions)
      end
    end

    context "when updated, and has many associated polymorphic objects" do
      it "copy the has_many associations when reifying" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.whatchamajiggers.create(name: "f-zero")
        widget.whatchamajiggers.create(name: "f-zero")
        reified_widget = widget.versions.last.reify
        expect(reified_widget.whatchamajiggers.length).to eq(widget.whatchamajiggers.length)
        expect(reified_widget.whatchamajiggers).to match_array(widget.whatchamajiggers)
        expect(reified_widget.versions.length).to(eq(widget.versions.length))
        expect(reified_widget.versions).to match_array(widget.versions)
      end
    end

    context "when updated, polymorphic objects by themselves" do
      it "not fail with a nil pointer on the polymorphic association" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget = Whatchamajigger.new(name: "f-zero")
        widget.save!
      end
    end

    context "when updated, and then destroyed" do
      it "record the correct event" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.destroy
        expect(PaperTrail::Version.last.event).to(match(/destroy/i))
      end

      it "have three previous versions" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.destroy
        expect(PaperTrail::Version.with_item_keys("Widget", widget.id).length).to(eq(3))
      end

      it "returns the expected attributes for the reified widget" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
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

      it "be re-creatable from its previous version" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.destroy
        reified_widget = PaperTrail::Version.last.reify
        expect(reified_widget.save).to(be_truthy)
      end

      it "restore its associations on its previous version" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.fluxors.create(name: "flux")
        widget.destroy
        reified_widget = PaperTrail::Version.last.reify
        reified_widget.save
        expect(reified_widget.fluxors.length).to(eq(1))
      end

      it "have nil item for last version" do
        widget = described_class.create(name: "Henry")
        widget.update(name: "Harry")
        widget.destroy
        expect(widget.versions.first.item.object_id).not_to eq(widget.object_id)
        expect(widget.versions.last.item.object_id).not_to eq(widget.object_id)
        expect(widget.versions.last.item).to be_nil
      end
    end
  end

  context "with a record's papertrail" do
    let!(:d0) { Date.new(2009, 5, 29) }
    let!(:t0) { Time.current }
    let(:previous_widget) { widget.versions.last.reify }
    let(:widget) {
      described_class.create(
        name: "Warble",
        a_text: "The quick brown fox",
        an_integer: 42,
        a_float: 153.01,
        a_decimal: 2.71828,
        a_datetime: t0,
        a_time: t0,
        a_date: d0,
        a_boolean: true
      )
    }

    before do
      widget.update(
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
    end

    it "handle strings" do
      expect(previous_widget.name).to(eq("Warble"))
    end

    it "handle text" do
      expect(previous_widget.a_text).to(eq("The quick brown fox"))
    end

    it "handle integers" do
      expect(previous_widget.an_integer).to(eq(42))
    end

    it "handle floats" do
      assert_in_delta(153.01, previous_widget.a_float, 0.001)
    end

    it "handle decimals" do
      assert_in_delta(2.7183, previous_widget.a_decimal, 0.0001)
    end

    it "handle datetimes" do
      expect(previous_widget.a_datetime.to_time.utc.to_i).to(eq(t0.to_time.utc.to_i))
    end

    it "handle times (time only, no date)" do
      format = ->(t) { t.utc.strftime "%H:%M:%S" }
      expect(format[previous_widget.a_time]).to eq(format[t0])
    end

    it "handle dates" do
      expect(previous_widget.a_date).to(eq(d0))
    end

    it "handle booleans" do
      expect(previous_widget.a_boolean).to(be_truthy)
    end

    context "when a column has been removed from the record's schema" do
      let(:last_version) { widget.versions.last }

      it "reify previous version" do
        assert_kind_of(described_class, last_version.reify)
      end

      it "restore all forward-compatible attributes" do
        reified = last_version.reify
        expect(reified.name).to(eq("Warble"))
        expect(reified.a_text).to(eq("The quick brown fox"))
        expect(reified.an_integer).to(eq(42))
        assert_in_delta(153.01, reified.a_float, 0.001)
        assert_in_delta(2.7183, reified.a_decimal, 0.0001)
        expect(reified.a_datetime.to_time.utc.to_i).to(eq(t0.to_time.utc.to_i))
        format = ->(t) { t.utc.strftime "%H:%M:%S" }
        expect(format[reified.a_time]).to eq(format[t0])
        expect(reified.a_date).to(eq(d0))
        expect(reified.a_boolean).to(be_truthy)
      end
    end
  end

  context "with a record" do
    context "with PaperTrail globally disabled, when updated" do
      after { PaperTrail.enabled = true }

      it "not add to its trail" do
        widget = described_class.create(name: "Zaphod")
        PaperTrail.enabled = false
        count = widget.versions.length
        widget.update(name: "Beeblebrox")
        expect(widget.versions.length).to(eq(count))
      end
    end

    context "with its paper trail turned off, when updated" do
      after do
        PaperTrail.request.enable_model(described_class)
      end

      it "not add to its trail" do
        widget = described_class.create(name: "Zaphod")
        PaperTrail.request.disable_model(described_class)
        count = widget.versions.length
        widget.update(name: "Beeblebrox")
        expect(widget.versions.length).to(eq(count))
      end

      it "add to its trail" do
        widget = described_class.create(name: "Zaphod")
        PaperTrail.request.disable_model(described_class)
        count = widget.versions.length
        widget.update(name: "Beeblebrox")
        PaperTrail.request.enable_model(described_class)
        widget.update(name: "Ford")
        expect(widget.versions.length).to(eq((count + 1)))
      end
    end
  end

  context "with somebody making changes" do
    context "when a record is created" do
      it "tracks who made the change" do
        widget = described_class.new(name: "Fidget")
        PaperTrail.request.whodunnit = "Alice"
        widget.save
        version = widget.versions.last
        expect(version.whodunnit).to(eq("Alice"))
        expect(version.paper_trail_originator).to(be_nil)
        expect(version.terminator).to(eq("Alice"))
        expect(widget.paper_trail.originator).to(eq("Alice"))
      end
    end

    context "when created, then updated" do
      it "tracks who made the change" do
        widget = described_class.new(name: "Fidget")
        PaperTrail.request.whodunnit = "Alice"
        widget.save
        PaperTrail.request.whodunnit = "Bob"
        widget.update(name: "Rivet")
        version = widget.versions.last
        expect(version.whodunnit).to(eq("Bob"))
        expect(version.paper_trail_originator).to(eq("Alice"))
        expect(version.terminator).to(eq("Bob"))
        expect(widget.paper_trail.originator).to(eq("Bob"))
      end
    end

    context "when created, updated, and destroyed" do
      it "tracks who made the change" do
        widget = described_class.new(name: "Fidget")
        PaperTrail.request.whodunnit = "Alice"
        widget.save
        PaperTrail.request.whodunnit = "Bob"
        widget.update(name: "Rivet")
        PaperTrail.request.whodunnit = "Charlie"
        widget.destroy
        version = PaperTrail::Version.last
        expect(version.whodunnit).to(eq("Charlie"))
        expect(version.paper_trail_originator).to(eq("Bob"))
        expect(version.terminator).to(eq("Charlie"))
        expect(widget.paper_trail.originator).to(eq("Charlie"))
      end
    end
  end

  context "with an item with versions" do
    context "when the versions were created over time" do
      let(:widget) { described_class.create(name: "Widget") }
      let(:t0) { 2.days.ago }
      let(:t1) { 1.day.ago }
      let(:t2) { 1.hour.ago }

      before do
        widget.update(name: "Fidget")
        widget.update(name: "Digit")
        widget.versions[0].update(created_at: t0)
        widget.versions[1].update(created_at: t1)
        widget.versions[2].update(created_at: t2)
        widget.update_attribute(:updated_at, t2)
      end

      it "return nil for version_at before it was created" do
        expect(widget.paper_trail.version_at((t0 - 1))).to(be_nil)
      end

      it "return how it looked when created for version_at its creation" do
        expect(widget.paper_trail.version_at(t0).name).to(eq("Widget"))
      end

      it "return how it looked before its first update" do
        expect(widget.paper_trail.version_at((t1 - 1)).name).to(eq("Widget"))
      end

      it "return how it looked after its first update" do
        expect(widget.paper_trail.version_at(t1).name).to(eq("Fidget"))
      end

      it "return how it looked before its second update" do
        expect(widget.paper_trail.version_at((t2 - 1)).name).to(eq("Fidget"))
      end

      it "return how it looked after its second update" do
        expect(widget.paper_trail.version_at(t2).name).to(eq("Digit"))
      end

      it "return the current object for version_at after latest update" do
        expect(widget.paper_trail.version_at(1.day.from_now).name).to(eq("Digit"))
      end

      it "still return a widget when appropriate, when passing timestamp as string" do
        expect(
          widget.paper_trail.version_at((t0 + 1.second).to_s).name
        ).to(eq("Widget"))
        expect(
          widget.paper_trail.version_at((t1 + 1.second).to_s).name
        ).to(eq("Fidget"))
        expect(
          widget.paper_trail.version_at((t2 + 1.second).to_s).name
        ).to(eq("Digit"))
      end
    end

    describe ".versions_between" do
      it "return versions in the time period" do
        widget = described_class.create(name: "Widget")
        widget.update(name: "Fidget")
        widget.update(name: "Digit")
        widget.versions[0].update(created_at: 30.days.ago)
        widget.versions[1].update(created_at: 15.days.ago)
        widget.versions[2].update(created_at: 1.day.ago)
        widget.update_attribute(:updated_at, 1.day.ago)
        expect(
          widget.paper_trail.versions_between(20.days.ago, 10.days.ago).map(&:name)
        ).to(eq(["Fidget"]))
        expect(
          widget.paper_trail.versions_between(45.days.ago, 10.days.ago).map(&:name)
        ).to(eq(%w[Widget Fidget]))
        expect(
          widget.paper_trail.versions_between(16.days.ago, 1.minute.ago).map(&:name)
        ).to(eq(%w[Fidget Digit Digit]))
        expect(
          widget.paper_trail.versions_between(60.days.ago, 45.days.ago).map(&:name)
        ).to(eq([]))
      end
    end

    context "with the first version" do
      let(:widget) { described_class.create(name: "Widget") }
      let(:version) { widget.versions.last }

      before do
        widget = described_class.create(name: "Widget")
        widget.update(name: "Fidget")
        widget.update(name: "Digit")
      end

      it "have a nil previous version" do
        expect(version.previous).to(be_nil)
      end

      it "return the next version" do
        expect(version.next).to(eq(widget.versions[1]))
      end

      it "return the correct index" do
        expect(version.index).to(eq(0))
      end
    end

    context "with the last version" do
      let(:widget) { described_class.create(name: "Widget") }
      let(:version) { widget.versions.last }

      before do
        widget.update(name: "Fidget")
        widget.update(name: "Digit")
      end

      it "return the previous version" do
        expect(version.previous).to(eq(widget.versions[(widget.versions.length - 2)]))
      end

      it "have a nil next version" do
        expect(version.next).to(be_nil)
      end

      it "return the correct index" do
        expect(version.index).to(eq((widget.versions.length - 1)))
      end
    end

    describe "queries of versions" do
      let(:widget) { described_class.create(name: "Widget") }
      let(:eternal_widget) { described_class.create(name: "Ewigkeit") }
      let(:version) { widget.versions.last }

      before do
        widget.update(name: "Fidget")
        widget.update(name: "Digit")
      end

      if ENV["DB"] == "postgres"
        it "return the widget whose name has changed" do
          expect(PaperTrail::Version.where_attribute_changes(:name)).to include(widget)
        end

        it "returns the widget whose name was Fidget" do
          expect(PaperTrail::Version.where_object_changes_from({ name: "Fidget" })).to
            include(widget)
        end

        it "returns the widget whose name became Digit" do
          expect(PaperTrail::Version.where.object_changes_to({ name: "Digit"} )). to
            include(widget)
        end

        it "returns the widget where the object is eternal" do
          expect(PaperTrail::Version.where_object({ name: "Ewigkeit" })).to include(widget)
        end

        it "returns the widget that changed to Fidget" do
          expect(PaperTrail::Version.where_object_changes({ name: "Fidget" })).to include(widget)
        end
      end
    end
  end

  context "with a reified item" do
    it "know which version it came from, and return its previous self" do
      widget = described_class.create(name: "Bob")
      %w[Tom Dick Jane].each do |name|
        widget.update(name: name)
      end
      version = widget.versions.last
      widget = version.reify
      expect(widget.version).to(eq(version))
      expect(widget.paper_trail.previous_version).to(eq(widget.versions[-2].reify))
    end
  end

  describe "#next_version" do
    context "with a reified item" do
      it "returns the object (not a Version) as it became next" do
        widget = described_class.create(name: "Bob")
        %w[Tom Dick Jane].each do |name|
          widget.update(name: name)
        end
        second_widget = widget.versions[1].reify
        last_widget = widget.versions.last.reify
        expect(second_widget.paper_trail.next_version.name).to(eq(widget.versions[2].reify.name))
        expect(widget.name).to(eq(last_widget.paper_trail.next_version.name))
      end
    end

    context "with a non-reified item" do
      it "always returns nil because cannot ever have a next version" do
        widget = described_class.new
        expect(widget.paper_trail.next_version).to(be_nil)
        widget.save
        %w[Tom Dick Jane].each do |name|
          widget.update(name: name)
        end
        expect(widget.paper_trail.next_version).to(be_nil)
      end
    end
  end

  describe "#previous_version" do
    context "with a reified item" do
      it "returns the object (not a Version) as it was most recently" do
        widget = described_class.create(name: "Bob")
        %w[Tom Dick Jane].each do |name|
          widget.update(name: name)
        end
        second_widget = widget.versions[1].reify
        last_widget = widget.versions.last.reify
        expect(second_widget.paper_trail.previous_version).to(be_nil)
        expect(last_widget.paper_trail.previous_version.name).to(eq(widget.versions[-2].reify.name))
      end
    end

    context "with a non-reified item" do
      it "returns the object (not a Version) as it was most recently" do
        widget = described_class.new
        expect(widget.paper_trail.previous_version).to(be_nil)
        widget.save
        %w[Tom Dick Jane].each do |name|
          widget.update(name: name)
        end
        expect(widget.paper_trail.previous_version.name).to(eq(widget.versions.last.reify.name))
      end
    end
  end

  context "with an unsaved record" do
    it "not have a version created on destroy" do
      widget = described_class.new
      widget.destroy
      expect(widget.versions.empty?).to(eq(true))
    end
  end

  context "when measuring the memory allocation of" do
    let(:widget) do
      described_class.new(
        name: "Warble",
        a_text: "The quick brown fox",
        an_integer: 42,
        a_float: 153.01,
        a_decimal: 2.71828,
        a_boolean: true
      )
    end

    before do
      # Json fields for `object` & `object_changes` attributes is most efficient way
      # to do the things - this way we will save even more RAM, as well as will skip
      # the whole YAML serialization
      allow(PaperTrail::Version).to receive(:object_changes_col_is_json?).and_return(true)
      allow(PaperTrail::Version).to receive(:object_col_is_json?).and_return(true)

      # Force the loading of all lazy things like class definitions,
      # in order to get the pure benchmark
      version_building.call
    end

    describe "#build_version_on_create" do
      let(:version_building) do
        lambda do
          widget.paper_trail.send(
            :build_version_on_create,
            in_after_callback: false
          )
        end
      end

      it "is frugal enough" do
        # Some time ago there was 95kbs..
        # At the time of commit the test passes with assertion on 17kbs.
        # Lets assert 20kbs then, to avoid flaky fails.
        expect(&version_building).to allocate_less_than(20).kilobytes
      end
    end

    describe "#build_version_on_update" do
      let(:widget) do
        super().tap do |w|
          w.save!
          w.attributes = {
            name: "Dostoyevsky",
            a_text: "The slow yellow mouse",
            an_integer: 84,
            a_float: 306.02,
            a_decimal: 5.43656,
            a_boolean: false
          }
        end
      end
      let(:version_building) do
        lambda do
          widget.paper_trail.send(
            :build_version_on_update,
            force: false,
            in_after_callback: false,
            is_touch: false
          )
        end
      end

      it "is frugal enough" do
        # Some time ago there was 144kbs..
        # At the time of commit the test passes with assertion on 27kbs.
        # Lets assert 35kbs then, to avoid flaky fails.
        expect(&version_building).to allocate_less_than(35).kilobytes
      end
    end
  end

  describe "`be_versioned` matcher" do
    it { is_expected.to be_versioned }
  end

  describe "`have_a_version_with` matcher", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    before do
      widget.update!(name: "Leonard", an_integer: 1)
      widget.update!(name: "Tom")
      widget.update!(name: "Bob")
    end

    it "is possible to do assertions on version attributes" do
      expect(widget).to have_a_version_with name: "Leonard", an_integer: 1
      expect(widget).to have_a_version_with an_integer: 1
      expect(widget).to have_a_version_with name: "Tom"
    end
  end

  describe "versioning option" do
    context "when enabled", versioning: true do
      it "enables versioning" do
        widget = described_class.create! name: "Bob", an_integer: 1
        expect(widget.versions.size).to eq(1)
      end
    end

    context "when disabled", versioning: false do
      it "does not enable versioning" do
        widget = described_class.create! name: "Bob", an_integer: 1
        expect(widget.versions.size).to eq(0)
      end
    end
  end

  describe "Callbacks", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    describe "before_save" do
      it "resets value for timestamp attrs for update so that value gets updated properly" do
        widget.update!(name: "Foobar")
        w = widget.versions.last.reify
        expect { w.save! }.to change(w, :updated_at)
      end
    end

    describe "after_create" do
      let(:widget) { described_class.create!(name: "Foobar", created_at: Time.current - 1.week) }

      it "corresponding version uses the widget's `updated_at`" do
        expect(widget.versions.last.created_at.to_i).to eq(widget.updated_at.to_i)
      end
    end

    describe "after_update" do
      before do
        widget.update!(name: "Foobar", updated_at: Time.current + 1.week)
      end

      it "clears the `versions_association_name` virtual attribute" do
        w = widget.versions.last.reify
        expect(w.paper_trail).not_to be_live
        w.save!
        expect(w.paper_trail).to be_live
      end

      it "corresponding version uses the widget updated_at" do
        expect(widget.versions.last.created_at.to_i).to eq(widget.updated_at.to_i)
      end
    end

    describe "after_destroy" do
      it "creates a version for that event" do
        expect { widget.destroy }.to change(widget.versions, :count).by(1)
      end

      it "assigns the version into the `versions_association_name`" do
        expect(widget.version).to be_nil
        widget.destroy
        expect(widget.version).not_to be_nil
        expect(widget.version).to eq(widget.versions.last)
      end
    end

    describe "after_rollback" do
      let(:rolled_back_name) { "Big Moo" }

      before do
        widget.transaction do
          widget.update!(name: rolled_back_name)
          widget.update!(name: Widget::EXCLUDED_NAME)
        end
      rescue ActiveRecord::RecordInvalid
        widget.reload
        widget.name = nil
        widget.save
      end

      it "does not create an event for changes that did not happen" do
        widget.versions.map(&:changeset).each do |changeset|
          expect(changeset.fetch("name", [])).not_to include(rolled_back_name)
        end
      end

      it "has not yet loaded the assocation" do
        expect(widget.versions).not_to be_loaded
      end
    end
  end

  describe "Association", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    describe "sort order" do
      it "sorts by the timestamp order from the `VersionConcern`" do
        expect(widget.versions.to_sql).to eq(
          widget.versions.reorder(PaperTrail::Version.timestamp_sort_order).to_sql
        )
      end
    end
  end

  describe "#create", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    it "creates a version record" do
      wordget = described_class.create
      assert_equal 1, wordget.versions.length
    end
  end

  describe "#destroy", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    it "creates a version record" do
      widget = described_class.create
      assert_equal 1, widget.versions.length
      widget.destroy
      versions_for_widget = PaperTrail::Version.with_item_keys("Widget", widget.id)
      assert_equal 2, versions_for_widget.length
    end

    it "can have multiple destruction records" do
      versions = lambda { |widget|
        # Workaround for AR 3. When we drop AR 3 support, we can simply use
        # the `widget.versions` association, instead of `with_item_keys`.
        PaperTrail::Version.with_item_keys("Widget", widget.id)
      }
      widget = described_class.create
      assert_equal 1, widget.versions.length
      widget.destroy
      assert_equal 2, versions.call(widget).length
      widget = widget.version.reify
      widget.save
      assert_equal 3, versions.call(widget).length
      widget.destroy
      assert_equal 4, versions.call(widget).length
      assert_equal 2, versions.call(widget).where(event: "destroy").length
    end
  end

  describe "#paper_trail.originator", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    describe "return value" do
      let(:orig_name) { FFaker::Name.name }
      let(:new_name) { FFaker::Name.name }

      before do
        PaperTrail.request.whodunnit = orig_name
      end

      it "returns the originator for the model at a given state" do
        expect(widget.paper_trail).to be_live
        expect(widget.paper_trail.originator).to eq(orig_name)
        ::PaperTrail.request(whodunnit: new_name) {
          widget.update(name: "Elizabeth")
        }
        expect(widget.paper_trail.originator).to eq(new_name)
      end

      it "returns the appropriate originator" do
        widget.update(name: "Andy")
        PaperTrail.request.whodunnit = new_name
        widget.update(name: "Elizabeth")
        reified_widget = widget.versions[1].reify
        expect(reified_widget.paper_trail.originator).to eq(orig_name)
        expect(reified_widget).not_to be_new_record
      end

      it "can create a new instance with options[:dup]" do
        widget.update(name: "Andy")
        PaperTrail.request.whodunnit = new_name
        widget.update(name: "Elizabeth")
        reified_widget = widget.versions[1].reify(dup: true)
        expect(reified_widget.paper_trail.originator).to eq(orig_name)
        expect(reified_widget).to be_new_record
      end
    end
  end

  describe "#version_at", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    context "when Timestamp argument is AFTER object has been destroyed" do
      it "returns nil" do
        widget.update_attribute(:name, "foobar")
        widget.destroy
        expect(widget.paper_trail.version_at(Time.current)).to be_nil
      end
    end
  end

  describe "touch", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    it "creates a version" do
      expect { widget.touch }.to change {
        widget.versions.count
      }.by(+1)
    end

    context "when request is disabled" do
      it "does not create a version" do
        PaperTrail.request(enabled: false) do
          expect { widget.touch }.not_to(change { widget.versions.count })
        end
      end
    end
  end

  describe ".paper_trail.update_columns", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    it "creates a version record" do
      widget = described_class.create
      expect(widget.versions.count).to eq(1)
      widget.paper_trail.update_columns(name: "Bugle")
      expect(widget.versions.count).to eq(2)
      expect(widget.versions.last.event).to(eq("update"))
      expect(widget.versions.last.changeset[:name]).to eq([nil, "Bugle"])
    end
  end

  describe "#update", versioning: true do
    let(:widget) { described_class.create! name: "Bob", an_integer: 1 }

    it "creates a version record" do
      widget = described_class.create
      assert_equal 1, widget.versions.length
      widget.update(name: "Bugle")
      assert_equal 2, widget.versions.length
    end
  end
end
