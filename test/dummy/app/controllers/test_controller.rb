class TestController < ActionController::Base
  def current_user
    @current_user ||= OpenStruct.new(:id => Thread.current.object_id)
  end
end
