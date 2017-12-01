require "spec_helper"

RSpec.describe PaperTrail do
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
      expect(v).to be_a(::Gem::Version)
      expect(v.to_s).to eq(::PaperTrail::VERSION::STRING)
    end
  end

  context "when enabled" do
    it "affects all threads" do
      Thread.new { described_class.enabled = false }.join
      assert_equal false, described_class.enabled?
    end

    after do
      described_class.enabled = true
    end
  end

  context "default" do
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

    context "error within `with_versioning` block" do
      it "reverts the value of `PaperTrail.enabled?` to its previous state" do
        expect(described_class).not_to be_enabled
        expect { with_versioning { raise } }.to raise_error(RuntimeError)
        expect(described_class).not_to be_enabled
      end
    end
  end

  context "`versioning: true`", versioning: true do
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

  context "`with_versioning` block at class level" do
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
    it { expect(described_class).to respond_to(:version) }
    it { expect(described_class.version).to eq(described_class::VERSION::STRING) }
  end

  describe ".whodunnit" do
    context "with block passed" do
      it "sets whodunnit only for the block passed" do
        described_class.whodunnit("foo") do
          expect(described_class.whodunnit).to eq("foo")
        end

        expect(described_class.whodunnit).to be_nil
      end

      it "sets whodunnit only for the current thread" do
        described_class.whodunnit("foo") do
          expect(described_class.whodunnit).to eq("foo")
          Thread.new { expect(described_class.whodunnit).to be_nil }.join
        end

        expect(described_class.whodunnit).to be_nil
      end
    end

    context "when set to a proc" do
      it "evaluates the proc each time a version is made" do
        call_count = 0
        described_class.whodunnit = proc { call_count += 1 }
        expect(described_class.whodunnit).to eq(1)
        expect(described_class.whodunnit).to eq(2)
      end
    end
  end
end
