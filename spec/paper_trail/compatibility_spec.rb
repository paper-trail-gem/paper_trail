# frozen_string_literal: true

module PaperTrail
  ::RSpec.describe(Compatibility) do
    describe ".check_activerecord" do
      context "when compatible" do
        it "does not produce output" do
          ar_version = ::Gem::Version.new("7.1.0")
          expect {
            described_class.check_activerecord(ar_version)
          }.not_to output.to_stderr
        end
      end

      context "when incompatible" do
        it "writes a warning to stderr" do
          ar_version = ::Gem::Version.new("8.1.0")
          expect {
            described_class.check_activerecord(ar_version)
          }.to output(/not compatible/).to_stderr
        end
      end
    end
  end
end
