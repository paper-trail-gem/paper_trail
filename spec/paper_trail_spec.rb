# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaperTrail do
  describe ".request" do
    it "returns the value returned by the block" do
      expect(described_class.request(whodunnit: "abe lincoln") { "A test" }).to eq("A test")
    end
  end

  describe "#config", versioning: true do
    it "allows for config values to be set" do
      expect(described_class.config.enabled).to eq(true)
      described_class.config.enabled = false
      expect(described_class.config.enabled).to eq(false)
    end

    it "accepts blocks and yield the config instance" do
      expect(described_class.config.enabled).to eq(true)
      described_class.config { |c| c.enabled = false }
      expect(described_class.config.enabled).to eq(false)
    end
  end

  describe "#configure" do
    it "is an alias for the `config` method" do
      expect(described_class.method(:configure)).to eq(
        described_class.method(:config)
      )
    end
  end

  describe ".gem_version" do
    it "returns a Gem::Version" do
      v = described_class.gem_version
      expect(v).to be_a(Gem::Version)
      expect(v.to_s).to eq(PaperTrail::VERSION::STRING)
    end
  end

  context "when enabled" do
    after do
      described_class.enabled = true
    end

    it "affects all threads" do
      Thread.new { described_class.enabled = false }.join
      expect(described_class.enabled?).to eq(false)
    end
  end

  context "when default" do
    it "has versioning off by default" do
      expect(described_class).not_to be_enabled
    end

    it "has versioning on in a `with_versioning` block" do
      expect(described_class).not_to be_enabled
      with_versioning do
        expect(described_class).to be_enabled
      end
      expect(described_class).not_to be_enabled
    end

    context "when error within `with_versioning` block" do
      it "reverts the value of `PaperTrail.enabled?` to its previous state" do
        expect(described_class).not_to be_enabled
        expect { with_versioning { raise } }.to raise_error(RuntimeError)
        expect(described_class).not_to be_enabled
      end
    end
  end

  context "with `versioning: true`", versioning: true do
    it "has versioning on by default" do
      expect(described_class).to be_enabled
    end

    it "keeps versioning on after a with_versioning block" do
      expect(described_class).to be_enabled
      with_versioning do
        expect(described_class).to be_enabled
      end
      expect(described_class).to be_enabled
    end
  end

  context "with `with_versioning` block at class level" do
    it { expect(described_class).not_to be_enabled }

    with_versioning do
      it "has versioning on by default" do
        expect(described_class).to be_enabled
      end
    end
    it "does not leak the `enabled?` state into successive tests" do
      expect(described_class).not_to be_enabled
    end
  end

  describe ".version" do
    it "returns the expected String" do
      expect(described_class.version).to eq(described_class::VERSION::STRING)
    end
  end
end
