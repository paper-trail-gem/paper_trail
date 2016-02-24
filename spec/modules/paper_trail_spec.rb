require 'rails_helper'

describe PaperTrail, type: :module, versioning: true do
  describe '#config' do
    it { is_expected.to respond_to(:config) }

    it "should allow for config values to be set" do
      expect(subject.config).to be_enabled
      subject.config.enabled = false
      expect(subject.config).to_not be_enabled
    end

    it "should accept blocks and yield the config instance" do
      expect(subject.config).to be_enabled
      subject.config { |c| c.enabled = false }
      expect(subject.config).to_not be_enabled
    end
  end

  describe '#configure' do
    it { is_expected.to respond_to(:configure) }

    it "should be an alias for the `config` method" do
      expect(subject.method(:configure)).to eq(subject.method(:config))
    end
  end
end
