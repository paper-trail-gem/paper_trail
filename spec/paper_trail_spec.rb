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
    it "returns the expected String" do
      expect(described_class.version).to eq(described_class::VERSION::STRING)
    end
  end

  describe "deprecated methods" do
    before do
      allow(ActiveSupport::Deprecation).to receive(:warn)
    end

    shared_examples "it delegates to request" do |method, args|
      it do
        arguments = args || [no_args]
        allow(described_class.request).to receive(method)
        described_class.public_send(method, *args)
        expect(described_class.request).to have_received(method).with(*arguments)
        expect(ActiveSupport::Deprecation).to have_received(:warn)
      end
    end

    it_behaves_like "it delegates to request", :clear_transaction_id, nil
    it_behaves_like "it delegates to request", :enabled_for_model, [Widget, true]
    it_behaves_like "it delegates to request", :enabled_for_model?, [Widget]
    it_behaves_like "it delegates to request", :whodunnit=, [:some_whodunnit]
    it_behaves_like "it delegates to request", :whodunnit, nil
    it_behaves_like "it delegates to request", :controller_info=, [:some_whodunnit]
    it_behaves_like "it delegates to request", :controller_info, nil
    it_behaves_like "it delegates to request", :transaction_id=, 123
    it_behaves_like "it delegates to request", :transaction_id, nil

    describe "#enabled_for_controller=" do
      it "is deprecated" do
        allow(::PaperTrail.request).to receive(:enabled=)
        ::PaperTrail.enabled_for_controller = true
        expect(::PaperTrail.request).to have_received(:enabled=).with(true)
      end
    end

    describe "whodunnit with block" do
      it "delegates to request" do
        allow(described_class.request).to receive(:with)
        described_class.whodunnit(:some_whodunnit) { :some_block }
        expect(ActiveSupport::Deprecation).to have_received(:warn)
        expect(described_class.request).to have_received(:with) do |*args, &block|
          expect(args).to eq([{ whodunnit: :some_whodunnit }])
          expect(block.call).to eq :some_block
        end
      end
    end

    describe "whodunnit with invalid arguments" do
      it "raises an error" do
        expect { described_class.whodunnit(:some_whodunnit) }.to raise_error(ArgumentError) do |e|
          expect(e.message).to eq "Invalid arguments"
        end
      end
    end
  end
end
