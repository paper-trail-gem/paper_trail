# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe Config do
    describe ".instance" do
      it "returns the singleton instance" do
        expect { described_class.instance }.not_to raise_error
      end
    end

    describe ".new" do
      it "raises NoMethodError" do
        expect { described_class.new }.to raise_error(NoMethodError)
      end
    end

    describe "track_associations?" do
      context "@track_associations is nil" do
        it "returns false and prints a deprecation warning" do
          config = described_class.instance
          config.track_associations = nil
          expect(config.track_associations?).to eq(false)
        end

        after do
          ::ActiveSupport::Deprecation.silence do
            PaperTrail.config.track_associations = true
          end
        end
      end
    end

    describe ".version_limit", versioning: true do
      after { PaperTrail.config.version_limit = nil }

      it "limits the number of versions to 3 (2 plus the created at event)" do
        PaperTrail.config.version_limit = 2
        widget = Widget.create!(name: "Henry")
        6.times { widget.update_attribute(:name, FFaker::Lorem.word) }
        expect(widget.versions.first.event).to(eq("create"))
        expect(widget.versions.size).to(eq(3))
      end

      it "overrides the general limits to 4 (3 plus the created at event)" do
        PaperTrail.config.version_limit = 100
        bike = LimitedBicycle.create!(name: "Limited Bike") # has_paper_trail limit: 3
        10.times { bike.update_attribute(:name, FFaker::Lorem.word) }
        expect(bike.versions.first.event).to(eq("create"))
        expect(bike.versions.size).to(eq(4))
      end

      it "overrides the general limits with unlimited versions for model" do
        PaperTrail.config.version_limit = 10
        bike = UnlimitedBicycle.create!(name: "Unlimited Bike") # has_paper_trail limit: nil
        100.times.each do |i| bike.update_attribute(:name, "#{i} #{FFaker::Lorem.word}") end
        expect(bike.versions.first.event).to(eq("create"))
        expect(bike.versions.size).to(eq(101))
      end

      it "is not enabled on non-papertrail STI base classes, but enabled on subclasses" do
        PaperTrail.config.version_limit = 10
        vehicle = Vehicle.create!(name: "A Vehicle", type: "Vehicle")
        assert !vehicle.respond_to?(:versions)

        limited_bike = LimitedBicycle.create!(name: "Limited")
        assert limited_bike.respond_to?(:versions)
        limited_bike.name = "A new name"
        limited_bike.save
        assert_equal 2, limited_bike.versions.length
      end

      it "uses global version_limit and warns without item_subtype" do
        PaperTrail.config.version_limit = 30
        names = PaperTrail::Version.column_names - ["item_subtype"]
        allow(PaperTrail::Version).to receive(:column_names).and_return(names)

        # spy = spy("logger")
        # allow(::Rails).to receive(:logger).and_return(spy)
        # expect(spy).to have_received(:warn).with(/.*paper_trail WARNING.*/m)

        bike = LimitedBicycle.create!(name: "My Bike") # has_paper_trail limit: 3
        100.times do |i|
          bike.update(name: "Name #{i}")
        end
        assert_equal 31, bike.versions.length
      end
    end
  end
end
