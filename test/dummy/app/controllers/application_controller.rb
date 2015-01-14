class ApplicationController < ActionController::Base
  protect_from_forgery

  def rescue_action(e)
    raise e
  end

  # Returns id of hypothetical current user
  def current_user
    @current_user ||= OpenStruct.new(:id => 153).tap do |obj|
      # Invoking `id` returns the `object_id` value in Ruby18 unless specifically overwritten
      def obj.id; 153; end if RUBY_VERSION < '1.9'
    end
  end

  def info_for_paper_trail
    {:ip => request.remote_ip, :user_agent => request.user_agent}
  end
  
end
