# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe Cleaner, versioning: true do
    after do
      PaperTrail.config.version_limit = nil
    end

    it "cleans up old versions" do
      PaperTrail.config.version_limit = 10
      widget = Widget.create

      100.times do |i|
        widget.update_attributes(name: "Name #{i}")
        expect(Widget.find(widget.id).versions.count).to be <= 11
        # 11 versions = 10 updates + 1 create.
      end
    end

    it "deletes oldest versions, when the database returns them in a different order" do
      epoch = Date.new(2017, 1, 1)
      widget = Timecop.freeze(epoch) { Widget.create }

      # Sometimes a database will returns records in a different order than
      # they were inserted. That's hard to get the database to do, so we'll
      # just create them out-of-order:
      (1..5).to_a.shuffle.each do |n|
        Timecop.freeze(epoch + n.hours) do
          PaperTrail::Version.create!(
            item: widget,
            event: "update",
            object: { "id" => widget.id, "name" => "Name #{n}" }.to_yaml
          )
        end
      end
      expect(Widget.find(widget.id).versions.count).to eq(6) # 1 create + 5 updates

      # Now, we've recreated the scenario where we can accidentally clean up
      # the wrong versions. Re-enable the version_limit, and trigger the
      # clean-up:
      PaperTrail.config.version_limit = 3
      widget.versions.last.send(:enforce_version_limit!)

      # Verify that we have fewer versions:
      expect(widget.reload.versions.count).to eq(4) # 1 create + 4 updates

      # Exclude the create, because the create will return nil for `#reify`.
      last_names = widget.versions.not_creates.map(&:reify).map(&:name)
      expect(last_names).to eq(["Name 3", "Name 4", "Name 5"])
      # No matter what order the version records are returned it, we should
      # always keep the most-recent changes.
    end
  end
end
