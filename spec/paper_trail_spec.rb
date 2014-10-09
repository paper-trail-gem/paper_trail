require 'rails_helper'

describe "PaperTrail RSpec Helper" do
  context 'default' do
    it 'should have versioning off by default' do
      expect(PaperTrail).not_to be_enabled
    end
    it 'should turn versioning on in a `with_versioning` block' do
      expect(PaperTrail).not_to be_enabled
      with_versioning do
        expect(PaperTrail).to be_enabled
      end
      expect(PaperTrail).not_to be_enabled
    end

    context "error within `with_versioning` block" do
      it "should revert the value of `PaperTrail.enabled?` to it's previous state" do
        expect(PaperTrail).not_to be_enabled
        expect { with_versioning { raise } }.to raise_error
        expect(PaperTrail).not_to be_enabled
      end
    end
  end

  context '`versioning: true`', :versioning => true do
    it 'should have versioning on by default' do
      expect(PaperTrail).to be_enabled
    end
    it 'should keep versioning on after a with_versioning block' do
      expect(PaperTrail).to be_enabled
      with_versioning do
        expect(PaperTrail).to be_enabled
      end
      expect(PaperTrail).to be_enabled
    end
  end

  context '`with_versioning` block at class level' do
    it { expect(PaperTrail).not_to be_enabled }

    with_versioning do
      it 'should have versioning on by default' do
        expect(PaperTrail).to be_enabled
      end
    end
    it 'should not leak the `enabled?` state into successive tests' do
      expect(PaperTrail).not_to be_enabled
    end
  end

  describe :whodunnit do
    before(:all) { PaperTrail.whodunnit = 'foobar' }

    it "should get set to `nil` by default" do
      expect(PaperTrail.whodunnit).to be_nil
    end
  end

  describe :controller_info do
    before(:all) { ::PaperTrail.controller_info = {:foo => 'bar'} }

    it "should get set to an empty hash before each test" do
      expect(PaperTrail.controller_info).to eq({})
    end
  end
end
