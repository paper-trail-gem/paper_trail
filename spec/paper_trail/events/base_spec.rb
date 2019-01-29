# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Events
    ::RSpec.describe Base do
      describe "#changed_notably?", versioning: true do
        context "new record" do
          it "returns true" do
            g = Gadget.new(created_at: Time.now)
            event = PaperTrail::Events::Base.new(g, false)
            expect(event.changed_notably?).to eq(true)
          end
        end

        context "persisted record without update timestamps" do
          it "only acknowledges non-ignored attrs" do
            gadget = Gadget.create!(created_at: Time.now)
            gadget.name = "Wrench"
            event = PaperTrail::Events::Base.new(gadget, false)
            expect(event.changed_notably?).to eq(true)
          end

          it "does not acknowledge ignored attr (brand)" do
            gadget = Gadget.create!(created_at: Time.now)
            gadget.brand = "Acme"
            event = PaperTrail::Events::Base.new(gadget, false)
            expect(event.changed_notably?).to eq(false)
          end
        end

        context "persisted record with update timestamps" do
          it "only acknowledges non-ignored attrs" do
            gadget = Gadget.create!(created_at: Time.now)
            gadget.name = "Wrench"
            gadget.updated_at = Time.now
            event = PaperTrail::Events::Base.new(gadget, false)
            expect(event.changed_notably?).to eq(true)
          end

          it "does not acknowledge ignored attrs and timestamps only" do
            gadget = Gadget.create!(created_at: Time.now)
            gadget.brand = "Acme"
            gadget.updated_at = Time.now
            event = PaperTrail::Events::Base.new(gadget, false)
            expect(event.changed_notably?).to eq(false)
          end
        end
      end

      describe "#nonskipped_attributes_before_change", versioning: true do
        subject { event.send(:nonskipped_attributes_before_change, false) }

        let(:event) { PaperTrail::Events::Base.new(skipper, false) }
        let(:skipper) { Skipper.create!(another_timestamp: Time.now) }

        it do
          is_expected.not_to have_key("another_timestamp")
        end
      end
    end
  end
end
