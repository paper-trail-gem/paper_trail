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
        after do
          PaperTrail.config.track_associations = true
        end

        it "returns false and prints a deprecation warning" do
          config = described_class.instance
          config.track_associations = nil
          expect {
            expect(config.track_associations?).to eq(false)
          }.to output(/DEPRECATION WARNING/).to_stderr
        end
      end
    end
  end
end
