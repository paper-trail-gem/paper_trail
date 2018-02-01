# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe(Request, versioning: true) do
    describe ".enabled_for_model?" do
      it "returns true" do
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
      end
    end

    describe ".disable_model" do
      it "sets enabled_for_model? to false" do
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
        PaperTrail.request.disable_model(Widget)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(false)
      end

      after do
        PaperTrail.request.enable_model(Widget)
      end
    end

    describe ".enable_model" do
      it "sets enabled_for_model? to true" do
        PaperTrail.request.disable_model(Widget)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(false)
        PaperTrail.request.enable_model(Widget)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
      end

      after do
        PaperTrail.request.enable_model(Widget)
      end
    end

    describe ".whodunnit" do
      context "when set to a proc" do
        it "evaluates the proc each time a version is made" do
          call_count = 0
          described_class.whodunnit = proc { call_count += 1 }
          expect(described_class.whodunnit).to eq(1)
          expect(described_class.whodunnit).to eq(2)
        end
      end
    end

    describe ".with" do
      context "block given" do
        it "sets whodunnit only for the block passed" do
          described_class.with(whodunnit: "foo") do
            expect(described_class.whodunnit).to eq("foo")
          end
          expect(described_class.whodunnit).to be_nil
        end

        it "sets whodunnit only for the current thread" do
          described_class.with(whodunnit: "foo") do
            expect(described_class.whodunnit).to eq("foo")
            Thread.new { expect(described_class.whodunnit).to be_nil }.join
          end
          expect(described_class.whodunnit).to be_nil
        end
      end
    end
  end
end
