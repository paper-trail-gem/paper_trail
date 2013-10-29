require 'spec_helper'

describe PaperTrail::Version do
  it "should include the `VersionConcern` module to get base functionality" do
    PaperTrail::Version.should include(PaperTrail::VersionConcern)
  end

  describe "Attributes" do
    it { should have_db_column(:item_type).of_type(:string) }
    it { should have_db_column(:item_id).of_type(:integer) }
    it { should have_db_column(:event).of_type(:string) }
    it { should have_db_column(:whodunnit).of_type(:string) }
    it { should have_db_column(:object).of_type(:text) }
    it { should have_db_column(:created_at).of_type(:datetime) }
  end

  describe "Indexes" do
    it { should have_db_index([:item_type, :item_id]) }
  end

  describe "Methods" do
    describe "Instance" do
      subject { PaperTrail::Version.new(attributes) rescue PaperTrail::Version.new }

      describe :terminator do
        it { should respond_to(:terminator) }

        let(:attributes) { {:whodunnit => Faker::Name.first_name} }

        it "is an alias for the `whodunnit` attribute" do
          subject.whodunnit.should == attributes[:whodunnit]
        end
      end

      describe :version_author do
        it { should respond_to(:terminator) }

        it "should be an alias for the `terminator` method" do
          subject.method(:version_author).should == subject.method(:terminator)
        end
      end
    end
  end
end
