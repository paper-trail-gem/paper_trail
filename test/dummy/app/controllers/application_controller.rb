class ApplicationController < ActionController::Base
  protect_from_forgery

  def rescue_action(e)
    raise e
  end

  # Returns id of hypothetical current user
  def current_user
    153
  end

  def info_for_paper_trail
    {:ip => request.remote_ip, :user_agent => request.user_agent}
  end
  
end
