require File.dirname(__FILE__) + '/test_helper.rb'

class TestController < ActionController::Base
  
  def current_user
    @current_user ||= ActiveSupport::SecureRandom.hex(32)
  end

end

class ThreadSafeTest < Test::Unit::TestCase
  
  should "is thread safe when dealing with audit logging" do
    blocked = true
    
    blocked_thread = Thread.new do 
      controller = TestController.new
      controller.send(:set_whodunnit)
      begin
        puts "sleep for .001 sec"
        sleep(0.001)
      end while blocked
      PaperTrail.whodunnit
    end

    fast_running_thread = Thread.new do 
      controller = TestController.new
      controller.send(:set_whodunnit)
      blocked = false
      PaperTrail.whodunnit
    end
    assert_not_equal blocked_thread.value, fast_running_thread.value
  end
end