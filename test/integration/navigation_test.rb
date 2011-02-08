require 'test_helper'

class NavigationTest < ActiveSupport::IntegrationCase
  test 'Sanity test' do
    assert_kind_of Dummy::Application, Rails.application
  end
end
