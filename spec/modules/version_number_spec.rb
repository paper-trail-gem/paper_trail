require "spec_helper"

describe PaperTrail::VERSION do
  describe "Constants" do
    subject { PaperTrail::VERSION }

    describe "MAJOR" do
      it { is_expected.to be_const_defined(:MAJOR) }
      it { expect(subject::MAJOR).to be_a(Integer) }
    end
    describe "MINOR" do
      it { is_expected.to be_const_defined(:MINOR) }
      it { expect(subject::MINOR).to be_a(Integer) }
    end
    describe "TINY" do
      it { is_expected.to be_const_defined(:TINY) }
      it { expect(subject::TINY).to be_a(Integer) }
    end
    describe "PRE" do
      it { is_expected.to be_const_defined(:PRE) }
      if PaperTrail::VERSION::PRE
        it { expect(subject::PRE).to be_instance_of(String) }
      end
    end
    describe "STRING" do
      it { is_expected.to be_const_defined(:STRING) }
      it { expect(subject::STRING).to be_instance_of(String) }

      it "should join the numbers into a period separated string" do
        expect(subject::STRING).to eq(
          [subject::MAJOR, subject::MINOR, subject::TINY, subject::PRE].compact.join(".")
        )
      end
    end
  end
end
