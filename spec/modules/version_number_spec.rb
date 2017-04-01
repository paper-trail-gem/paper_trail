require "spec_helper"

RSpec.describe PaperTrail::VERSION do
  describe "STRING" do
    it "should join the numbers into a period separated string" do
      expect(described_class::STRING).to eq(
        [
          described_class::MAJOR,
          described_class::MINOR,
          described_class::TINY,
          described_class::PRE
        ].compact.join(".")
      )
    end
  end
end
