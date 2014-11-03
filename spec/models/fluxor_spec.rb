require 'rails_helper'

describe Fluxor, :type => :model do
  describe '`be_versioned` matcher' do
    it { is_expected.to_not be_versioned }
  end

  describe "Methods" do
    describe "Class" do
      subject { Fluxor }

      describe "#paper_trail_enabled_for_model?" do
        it { is_expected.to respond_to(:paper_trail_enabled_for_model?) }

        it { expect(subject.paper_trail_enabled_for_model?).to be false }
      end
    end
  end
end
