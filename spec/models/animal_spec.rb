require 'rails_helper'

describe Animal, :type => :model do
  it { is_expected.to be_versioned }

  describe "STI", :versioning => true do
    it { expect(Animal.inheritance_column).to eq('species') }

    describe "updates to the `inheritance_column`" do
      subject { Cat.create!(:name => 'Leo') }

      it "should be allowed" do
        subject.update_attributes(:name => 'Spike', :species => 'Dog')
        dog = Animal.find(subject.id)
        expect(dog).to be_instance_of(Dog)
      end
    end
  end
end
