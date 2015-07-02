require 'rails_helper'

module Kitchen
  describe Banana, :type => :model do
    it { is_expected.to be_versioned }

    describe '#versions' do
      it "returns instances of Kitchen::BananaVersion", :versioning => true do
        banana = described_class.create!
        expect(banana.versions.first).to be_a(Kitchen::BananaVersion)
      end
    end
  end
end
