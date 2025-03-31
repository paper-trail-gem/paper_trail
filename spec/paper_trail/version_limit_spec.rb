# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe Cleaner, versioning: true do
    after do
      PaperTrail.config.version_limit = nil
    end

    it "cleans up old versions with limit specified in model" do
      PaperTrail.config.version_limit = 10

      # LimitedBicycle overrides the global version_limit
      bike = LimitedBicycle.create(name: "Bike") # has_paper_trail limit: 3

      15.times do |i|
        bike.update(name: "Name #{i}")
      end
      expect(LimitedBicycle.find(bike.id).versions.count).to eq(4)
      # 4 versions = 3 updates + 1 create.
    end

    it "cleans up old versions with limit specified on base class" do
      PaperTrail.config.version_limit = 10

      Animal.paper_trail_options[:limit] = 5
      Dog.paper_trail_options = Animal.paper_trail_options.without(:limit)

      dog = Dog.create(name: "Fluffy") # Dog specified has_paper_trail with no limit option

      15.times do |i|
        dog.update(name: "Name #{i}")
      end
      expect(Dog.find(dog.id).versions.count).to eq(6) # Dog uses limit option on base class, Animal
      # 6 versions = 5 updates + 1 create.
    end

    it "cleans up old versions" do
      PaperTrail.config.version_limit = 10
      widget = Widget.create

      100.times do |i|
        widget.update(name: "Name #{i}")
        expect(Widget.find(widget.id).versions.count).to be <= 11
        # 11 versions = 10 updates + 1 create.
      end
    end

    it "deletes oldest versions, when the database returns them in a different order" do
      epoch = Date.new(2017, 1, 1)
      widget = Widget.create(created_at: epoch)

      # Sometimes a database will returns records in a different order than
      # they were inserted. That's hard to get the database to do, so we'll
      # just create them out-of-order:
      (1..5).to_a.shuffle.each do |n|
        PaperTrail::Version.create!(
          created_at: epoch + n.hours,
          item: widget,
          event: "update",
          object: { "id" => widget.id, "name" => "Name #{n}" }.to_yaml
        )
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
      last_names = widget.versions.not_creates.map { |x| x.reify.name }
      expect(last_names).to eq(["Name 3", "Name 4", "Name 5"])
      # No matter what order the version records are returned it, we should
      # always keep the most-recent changes.
    end
  end
end
