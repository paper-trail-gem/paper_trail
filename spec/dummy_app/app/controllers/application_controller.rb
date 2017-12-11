# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery

  # Some applications and libraries modify `current_user`. Their changes need
  # to be reflected in `whodunnit`, so the `set_paper_trail_whodunnit` below
  # must happen after this.
  before_action :modify_current_user

  # PT used to add this callback automatically. Now people are required to add
  # it themsevles, like this, allowing them to control the order of callbacks.
  # The `modify_current_user` callback above shows why this control is useful.
  before_action :set_paper_trail_whodunnit

  def rescue_action(e)
    raise e
  end

  # Returns id of hypothetical current user
  attr_reader :current_user

  def info_for_paper_trail
    { ip: request.remote_ip, user_agent: request.user_agent }
  end

  private

  def modify_current_user
    @current_user = OpenStruct.new(id: 153)
  end
end
