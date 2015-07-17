require 'rails_helper'

describe Gadget, :type => :model do
  it { is_expected.to be_versioned }

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

  describe "Methods" do
    describe "Instance", :versioning => true do
      describe "private" do
        describe '#changed_notably?' do
          subject { Gadget.new(:created_at => Time.now) }

          # apparently the private methods list in Ruby18 is different than in Ruby19+
          if RUBY_VERSION >= '1.9'
            it { expect(subject.private_methods).to include(:changed_notably?) }
          else
            it { expect(subject.private_methods).to include('changed_notably?') }
          end

          context "create events" do
            it { expect(subject.send(:changed_notably?)).to be true }
          end

          context "update events" do
            before { subject.save! }

            context "without update timestamps" do
              it "should only acknowledge non-ignored attrs" do
                subject.name = 'Wrench'
                expect(subject.send(:changed_notably?)).to be true
              end

              it "should not acknowledge ignored attr (brand)" do
                subject.brand = 'Acme'
                expect(subject.send(:changed_notably?)).to be false
              end
            end

            context "with update timestamps" do
              it "should only acknowledge non-ignored attrs" do
                subject.name, subject.updated_at = 'Wrench', Time.now
                expect(subject.send(:changed_notably?)).to be true
              end

              it "should not acknowledge ignored attrs and timestamps only" do
                subject.brand, subject.updated_at = 'Acme', Time.now
                expect(subject.send(:changed_notably?)).to be false
              end
            end
          end
        end
      end
    end
  end
end
