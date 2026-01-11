# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chair, :versioning do
  context "with raise_on_assign_to_attr_readonly enabled" do
    around do |example|
      # Temporarily enable the config
      original_value = ActiveRecord.raise_on_assign_to_attr_readonly
      ActiveRecord.raise_on_assign_to_attr_readonly = true

      example.run
    ensure
      ActiveRecord.raise_on_assign_to_attr_readonly = original_value
    end

    def create_versioned_record(klass)
      record = klass.create
      # To enable reify execution, the version object must not be nil.
      # Additionally, since ActiveRecord.raise_on_assign_to_attr_readonly
      # only applies to persisted objects, avoid using destroy with klass.new
      # and instead use the update method.
      record.update(color: "red")
      raise "Setup failed: versions not created" unless record.versions.count == 2
      raise "Setup failed: object is nil" if record.versions.last.object.nil?

      record
    end

    let(:chair) { create_versioned_record(described_class) }
    let(:chair_with_readonly) { create_versioned_record(ChairWithReadonly) }

    context "without bypass" do
      before do
        allow(PaperTrail::AttributeReadonlyBypass).to receive(:with_bypass!).and_yield
      end

      it "does not raise when reifying Chair without attr_readonly" do
        chair = create_versioned_record(described_class)
        expect { chair.versions.last.reify }.not_to raise_error
      end

      # When raise_on_assign_to_attr_readonly is enabled and we reify to a previous state,
      # it would raise an error because reify attempts to assign the readonly attribute
      # to the existing record loaded from the database
      it "raises when reifying a model with attr_readonly" do
        expect { chair_with_readonly.versions.last.reify }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end
    end

    context "with bypass" do
      it "does not raise when reifying Chair without attr_readonly" do
        expect { chair.versions.last.reify }.not_to raise_error
      end

      it "does not raise when reifying a model with attr_readonly" do
        expect { chair_with_readonly.versions.last.reify }.not_to raise_error
      end

      it "is thread-safe and does not affect other threads" do
        errors = []
        threads = []

        # Thread that reifies the model (bypasses readonly check)
        5.times do |i|
          threads << Thread.new do
            10.times do
              chair_with_readonly.versions.last.reify
            rescue StandardError => e
              errors << "Reify thread #{i}: #{e.class}: #{e.message}"
            end
          end
        end

        # Thread that checks _attr_readonly while others are reifying
        # Should always see the original readonly attributes, never empty
        threads << Thread.new do
          50.times do
            readonly_attrs = ChairWithReadonly._attr_readonly
            if readonly_attrs.empty?
              errors << "Checker thread: _attr_readonly was empty!"
            end
            sleep 0.001
          end
        end

        threads.each(&:join)
        expect(errors).to be_empty, "Thread safety issues detected: #{errors.join(', ')}"
      end
    end
  end
end
