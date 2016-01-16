require "rails_helper"

module PaperTrail
  RSpec.describe Config do
    describe ".instance" do
      it "returns the singleton instance" do
        expect { described_class.instance }.to_not raise_error
      end
    end

    describe ".new" do
      it "raises NoMethodError" do
        expect { described_class.new }.to raise_error(NoMethodError)
      end
    end

    describe "#enabled?" do
      context "when paper_trail_enabled is true" do
        it "returns true" do
          store = double
          allow(store).to receive(:fetch).
            with(:paper_trail_enabled, true).
            and_return(true)
          allow(PaperTrail).to receive(:paper_trail_store).and_return(store)
          expect(described_class.instance.enabled?).to eq(true)
        end
      end

      context "when paper_trail_enabled is false" do
        it "returns false" do
          store = double
          allow(store).to receive(:fetch).
            with(:paper_trail_enabled, true).
            and_return(false)
          allow(PaperTrail).to receive(:paper_trail_store).and_return(store)
          expect(described_class.instance.enabled?).to eq(false)
        end
      end

      context "when paper_trail_enabled is nil" do
        it "returns true" do
          store = double
          allow(store).to receive(:fetch).
            with(:paper_trail_enabled, true).
            and_return(nil)
          allow(PaperTrail).to receive(:paper_trail_store).and_return(store)
          expect(described_class.instance.enabled?).to eq(true)
        end
      end
    end
  end
end
