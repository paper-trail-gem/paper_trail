require 'rails_helper'

describe Animal, type: :model do
  it { is_expected.to be_versioned }

  describe "STI", versioning: true do
    it { expect(Animal.inheritance_column).to eq('species') }

    describe "updates to the `inheritance_column`" do
      subject { Cat.create!(name: 'Leo') }

      it "should be allowed" do
        subject.update_attributes(name: 'Spike', species: 'Dog')
        dog = Animal.find(subject.id)
        expect(dog).to be_instance_of(Dog)
      end
    end

    context 'with callback-methods' do
      context 'when only has_paper_trail set in super class' do
        let(:callback_cat) { Cat.create(name: 'Markus') }

        it 'trails all events' do
          callback_cat.update_attributes(name: 'Billie')
          callback_cat.destroy
          expect(callback_cat.versions.collect(&:event)).to eq %w(create update destroy)
        end

        it 'does not break reify' do
          callback_cat.destroy
          expect { callback_cat.versions.last.reify }.not_to raise_error
        end
      end
    end
  end
end
