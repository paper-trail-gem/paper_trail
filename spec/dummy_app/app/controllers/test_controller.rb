# frozen_string_literal: true

class TestController < ActionController::Base
  def user_for_paper_trail
    Thread.current.object_id
  end
end
