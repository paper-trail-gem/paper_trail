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

    describe ".version_error_behavior", versioning: true do
      let(:logger) { instance_double(Logger) }

      before do
        allow(logger).to receive(:warn)
        allow(logger).to receive(:debug?).and_return(false)

        ActiveRecord::Base.logger = logger
      end

      after do
        ActiveRecord::Base.logger = nil
      end

      context "when :legacy" do
        context "when version cannot be created" do
          before { PaperTrail.config.version_error_behavior = :legacy }

          it "raises an error but does not log on create" do
            expect {
              Comment.create!(content: "Henry")
            }.to raise_error(ActiveRecord::RecordInvalid)

            expect(logger).not_to have_received(:warn)
          end

          it "logs but does not raise error on update" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update!(content: "Brad")
            }.not_to raise_error

            expect(logger).to have_received(:warn)
          end

          it "does not raise error or log on update_columns" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update_columns(content: "Brad")
            }.not_to raise_error

            expect(logger).not_to have_received(:warn)
          end

          it "logs but does not raise error on destroy" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.destroy!
            }.not_to raise_error

            expect(logger).to have_received(:warn)
          end
        end
      end

      context "when exception" do
        context "when version cannot be created" do
          before { PaperTrail.config.version_error_behavior = :exception }

          after { PaperTrail.config.version_error_behavior = :legacy }

          it "raises an error but does not log on create" do
            expect {
              Comment.create!(content: "Henry")
            }.to raise_error(ActiveRecord::RecordInvalid)

            expect(logger).not_to have_received(:warn)
          end

          it "raises an error but does not on update" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update!(content: "Brad")
            }.to raise_error(ActiveRecord::RecordInvalid)

            expect(logger).not_to have_received(:warn)
          end

          it "does not raise an error or log on update_columns" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update_columns(content: "Brad")
            }.not_to raise_error

            expect(logger).not_to have_received(:warn)
          end

          it "raises an error but does not log on destroy" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.destroy!
            }.to raise_error(ActiveRecord::RecordInvalid)

            expect(logger).not_to have_received(:warn)
          end
        end
      end

      context "when log" do
        context "when version cannot be created" do
          before { PaperTrail.config.version_error_behavior = :log }

          after { PaperTrail.config.version_error_behavior = :legacy }

          it "logs and does not raise an error on create" do
            expect {
              Comment.create!(content: "Henry")
            }.not_to raise_error

            expect(logger).to have_received(:warn)
          end

          it "logs and does not raise an error on update" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update!(content: "Brad")
            }.not_to raise_error

            expect(logger).to have_received(:warn)
          end

          it "does not raise an error or log on update_columns" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update_columns(content: "Brad")
            }.not_to raise_error

            expect(logger).not_to have_received(:warn)
          end

          it "logs and does not raise an error on destroy" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.destroy!
            }.not_to raise_error

            expect(logger).to have_received(:warn)
          end
        end
      end

      context "when silent" do
        context "when version cannot be created" do
          before { PaperTrail.config.version_error_behavior = :silent }

          after { PaperTrail.config.version_error_behavior = :legacy }

          it "does not log or raise an error on create" do
            expect {
              Comment.create!(content: "Henry")
            }.not_to raise_error

            expect(logger).not_to have_received(:warn)
          end

          it "does not log or raise an error on update" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update!(content: "Brad")
            }.not_to raise_error

            expect(logger).not_to have_received(:warn)
          end

          it "does not log or raise an error on update_columns" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.update_columns(content: "Brad")
            }.not_to raise_error

            expect(logger).not_to have_received(:warn)
          end

          it "does not log or raise an error on destroy" do
            comment = PaperTrail.request(whodunnit: "Foo") do
              Comment.create!(content: "Henry")
            end

            expect {
              comment.destroy!
            }.not_to raise_error

            expect(logger).not_to have_received(:warn)
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
        expect(limited_bike.versions.length).to eq(2)
      end
    end
  end
end
