require 'spec_helper'

describe 'PaperTrail::VERSION' do

  describe "Constants" do
    subject { PaperTrail::VERSION }

    describe :MAJOR do
      it { should be_const_defined(:MAJOR) }
      it { subject::MAJOR.should be_a(Integer) }
    end
    describe :MINOR do
      it { should be_const_defined(:MINOR) }
      it { subject::MINOR.should be_a(Integer) }
    end
    describe :TINY do
      it { should be_const_defined(:TINY) }
      it { subject::TINY.should be_a(Integer) }
    end
    describe :PRE do
      it { should be_const_defined(:PRE) }
      if PaperTrail::VERSION::PRE
        it { subject::PRE.should be_instance_of(String) }
      end
    end
    describe :STRING do
      it { should be_const_defined(:STRING) }
      it { subject::STRING.should be_instance_of(String) }

      it "should join the numbers into a period separated string" do
        subject::STRING.should ==
          [subject::MAJOR, subject::MINOR, subject::TINY, subject::PRE].compact.join('.')
      end
    end
  end

end

describe PaperTrail do
  describe :version do
    it { should respond_to(:version) }
    its(:version) { should == PaperTrail::VERSION::STRING }
  end
end
