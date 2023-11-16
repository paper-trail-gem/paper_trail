# frozen_string_literal: true

require "securerandom"
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

    describe ".always_raise_on_error", versioning: true do
      context "when true" do
        context "when version cannot be created" do
          before { PaperTrail.config.always_raise_on_error = true }

          after { PaperTrail.config.always_raise_on_error = false }

          it "raises an error on create" do
            expect {
              Comment.create!(content: "Henry")
            }.to raise_error(ActiveRecord::NotNullViolation)
          end

          it "raises an error on update" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update!(content: "Brad")
            }.to raise_error(ActiveRecord::NotNullViolation)
          end

          it "raises an error on update_columns" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update_columns(content: "Brad")
            }.not_to raise_error
          end

          it "raises an error on destroy" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.destroy!
            }.to raise_error(ActiveRecord::NotNullViolation)
          end
        end
      end

      context "when false" do
        context "when version cannot be created" do
          before { PaperTrail.config.always_raise_on_error = false }

          it "raises an error on create" do
            expect {
              Comment.create!(content: "Henry")
            }.to raise_error(ActiveRecord::NotNullViolation)
          end

          it "does not raise an error on update" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update!(content: "Brad")
            }.not_to raise_error
          end

          it "does not raise an error on update_columns" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update_columns(content: "Brad")
            }.not_to raise_error
          end

          it "does not raises an error on destroy" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.destroy!
            }.not_to raise_error
          end
        end
      end
    end

    describe ".version_limit", versioning: true do
      after { PaperTrail.config.version_limit = nil }

      it "limits the number of versions to 3 (2 plus the created at event)" do
        PaperTrail.config.version_limit = 2
        widget = Widget.create!(name: "Henry")
        6.times { widget.update_attribute(:name, SecureRandom.hex(8)) }
        expect(widget.versions.first.event).to(eq("create"))
        expect(widget.versions.size).to(eq(3))
      end

      it "overrides the general limits to 4 (3 plus the created at event)" do
        PaperTrail.config.version_limit = 100
        bike = LimitedBicycle.create!(name: "Limited Bike") # has_paper_trail limit: 3
        10.times { bike.update_attribute(:name, SecureRandom.hex(8)) }
        expect(bike.versions.first.event).to(eq("create"))
        expect(bike.versions.size).to(eq(4))
      end

      it "overrides the general limits with unlimited versions for model" do
        PaperTrail.config.version_limit = 3
        bike = UnlimitedBicycle.create!(name: "Unlimited Bike") # has_paper_trail limit: nil
        6.times { bike.update_attribute(:name, SecureRandom.hex(8)) }
        expect(bike.versions.first.event).to(eq("create"))
        expect(bike.versions.size).to eq(7)
      end

      it "is not enabled on non-papertrail STI base classes, but enabled on subclasses" do
        PaperTrail.config.version_limit = 10
        Vehicle.create!(name: "A Vehicle", type: "Vehicle")
        limited_bike = LimitedBicycle.create!(name: "Limited")
        limited_bike.name = "A new name"
        limited_bike.save
        assert_equal 2, limited_bike.versions.length
      end
    end
  end
end
