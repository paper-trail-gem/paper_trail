require 'spec_helper'

describe Gadget do
  it { should be_versioned }

  let(:gadget) { Gadget.create!(:name => 'Wrench', :brand => 'Acme') }

  describe "updates", :versioning => true do
    it "should generate a version for updates to `name` attribute" do
      expect { gadget.update_attribute(:name, 'Hammer').to change{gadget.versions.size}.by(1) }
    end

    it "should ignore for updates to `brand` attribute" do
      expect { gadget.update_attribute(:brand, 'Stanley') }.to_not change{gadget.versions.size}
    end

    it "should still generate a version when only the `updated_at` attribute is updated" do
      expect { gadget.update_attribute(:updated_at, Time.now) }.to change{gadget.versions.size}.by(1)
    end
  end
end
