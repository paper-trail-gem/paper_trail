require 'rails_helper'

module PaperTrail
  RSpec.describe Cleaner, versioning: true do
    before do
      @last_limit = PaperTrail.config.version_limit
    end
    after do
      PaperTrail.config.version_limit = @last_limit
    end

    it 'cleans up old versions' do
      PaperTrail.config.version_limit = 10
      widget = Widget.create

      100.times do |i|
        widget.update_attributes(name: "Name #{i}")
        expect(Widget.find(widget.id).versions.count).to be <= 11
        # 11 versions = 10 updates + 1 create.
      end
    end

    it "cleans them up in the right order, even if the database query returns them in a different order" do
      epoch = DateTime.new(2017, 1, 1)

      # Turn off the version_limit, and make a bunch of versions.
      PaperTrail.config.version_limit = nil

      widget = Timecop.freeze(epoch) do
        Widget.create(name: 'Starting Name')
      end

      Timecop.freeze(epoch + 1.hours) { widget.update_attributes(name: 'Name 1') }
      Timecop.freeze(epoch + 2.hours) { widget.update_attributes(name: 'Name 2') }
      Timecop.freeze(epoch + 3.hours) { widget.update_attributes(name: 'Name 3') }
      Timecop.freeze(epoch + 4.hours) { widget.update_attributes(name: 'Name 4') }
      Timecop.freeze(epoch + 5.hours) { widget.update_attributes(name: 'Name 5') }

      # Here comes the crazy part.
      #
      # We want the database to return PaperTrail::Versions out of order. So
      # we'll delete what's there, shuffle them, and re-create them, but with
      # the same data, including the created_at timestamps. This will simulate
      # what happens when the database optimizes a query, and returns the
      # records in a different order than they were inserted in.
      # Load the records:
      versions = PaperTrail::Version.where(item: widget).not_creates.to_a

      # Delete the records, but don't let the in-memory objects know.
      PaperTrail::Version.where(id: versions.map(&:id)).delete_all

      # Are the versions deleted?
      expect(Widget.find(widget.id).versions.count).to eq(1)
      # Yes: only the create is left.

      # Shuffle them, and re-create them.
      versions.shuffle.each do |version|
        Timecop.freeze(version.created_at) do
          PaperTrail::Version.create!(
            event: version.event,
            item_type: version.item_type,
            item_id: version.item_id,
            object: version.object,
          )
        end
      end
      expect(Widget.find(widget.id).versions.count).to eq(6)

      # Sorting by ID should match insertion order. We can be confident that
      # the records are out of order, if sorting by ID doesn't match sorting by
      # created_at.
      ids_and_dates = PaperTrail::Version.
        where(item: widget, event: 'update').
        pluck(:id, :created_at)
      expect(ids_and_dates.sort_by(&:first)).to_not eq(
        ids_and_dates.sort_by(&:last)
      )

      # Now, we've recreated the scenario where we can accidentally clean up
      # the wrong versions. Re-enable the version_limit, and make one more
      # wafer-thin update, to trigger the clean-up:
      PaperTrail.config.version_limit = 3
      Timecop.freeze(epoch + 6.hours) do
        widget.update_attributes(name: 'Mr. Creosote')
      end

      # Verify that we have fewer versions:
      expect(widget.reload.versions.count).to eq(4)

      # Exclude the create, because the create will return nil for `#reify`.
      last_names = widget.versions.not_creates.map(&:reify).map(&:name)
      expect(last_names).to eq(['Name 3', 'Name 4', 'Name 5'])
      # No matter what order the version records are returned it, we should
      # always keep the most-recent changes.
    end
  end
end
