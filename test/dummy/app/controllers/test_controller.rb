class TestController < ActionController::Base
  def current_user
    Thread.current.object_id
  end
end
