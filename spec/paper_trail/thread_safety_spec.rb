# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaperTrail do
  describe "#set_paper_trail_whodunnit" do
    it "is thread-safe" do
      blocked = true
      slow_thread = Thread.new do
        controller = TestController.new
        controller.send(:set_paper_trail_whodunnit)
        sleep(0.001) while blocked
        described_class.request.whodunnit
      end
      fast_thread = Thread.new do
        controller = TestController.new
        controller.send(:set_paper_trail_whodunnit)
        who = described_class.request.whodunnit
        blocked = false
        who
      end
      expect(fast_thread.value).not_to(eq(slow_thread.value))
    end
  end

  describe "#without_versioning" do
    it "is thread-safe" do
      allow(::ActiveSupport::Deprecation).to receive(:warn)
      enabled = nil
      t1 = Thread.new do
        Widget.new.paper_trail.without_versioning do
          sleep(0.01)
          enabled = described_class.request.enabled_for_model?(Widget)
          sleep(0.01)
        end
        enabled
      end
      # A second thread is timed so that it runs during the first thread's
      # `without_versioning` block.
      t2 = Thread.new do
        sleep(0.005)
        described_class.request.enabled_for_model?(Widget)
      end
      expect(t1.value).to eq(false)
      expect(t2.value).to eq(true) # see? unaffected by t1
      expect(described_class.request.enabled_for_model?(Widget)).to eq(true)
      expect(::ActiveSupport::Deprecation).to have_received(:warn).once
    end
  end
end
