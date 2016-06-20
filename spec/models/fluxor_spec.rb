require "rails_helper"

describe Fluxor, type: :model do
  describe "`be_versioned` matcher" do
    it { is_expected.to_not be_versioned }
  end

  describe "Methods" do
    describe "Class" do
      describe ".paper_trail.enabled?" do
        it "returns false" do
          expect(Fluxor.paper_trail.enabled?).to eq(false)
        end
      end
    end
  end
end
