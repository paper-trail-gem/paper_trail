require 'test_helper'

class ThreadSafetyTest < ActionController::TestCase
  should "be thread safe" do
    blocked = true

    slow_thread = Thread.new do
      controller = TestController.new
      controller.send :set_whodunnit
      begin
        sleep 0.001
      end while blocked
      PaperTrail.whodunnit
    end

    fast_thread = Thread.new do
      controller = TestController.new
      controller.send :set_whodunnit
      who = PaperTrail.whodunnit
      blocked = false
      who
    end

    assert_not_equal slow_thread.value, fast_thread.value
  end
end
