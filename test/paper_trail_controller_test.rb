require File.dirname(__FILE__) + '/test_helper.rb'

class ApplicationController < ActionController::Base
  def rescue_action(e)
    raise e
  end

  # Returns id of hypothetical current user
  def current_user
    153
  end
end

class WidgetsController < ApplicationController
  def create
    @widget = Widget.create params[:widget]
    head :ok
  end

  def update
    @widget = Widget.find params[:id]
    @widget.update_attributes params[:widget]
    head :ok
  end

  def destroy
    @widget = Widget.find params[:id]
    @widget.destroy
    head :ok
  end
end


class PaperTrailControllerTest < ActionController::TestCase #Test::Unit::TestCase
  def setup
    @controller = WidgetsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    ActionController::Routing::Routes.draw do |map|
      map.resources :widgets
    end
  end

  test 'create' do
    post :create, :widget => { :name => 'Flugel' }
    widget = assigns(:widget)
    assert_equal 1, widget.versions.length
    assert_equal 153, widget.versions.last.whodunnit.to_i
  end

  test 'update' do
    w = Widget.create :name => 'Duvel'
    assert_equal 1, w.versions.length
    put :update, :id => w.id, :widget => { :name => 'Bugle' }
    widget = assigns(:widget)
    assert_equal 2, widget.versions.length
    assert_equal 153, widget.versions.last.whodunnit.to_i
  end

  test 'destroy' do
    w = Widget.create :name => 'Roundel'
    assert_equal 1, w.versions.length
    delete :destroy, :id => w.id
    widget = assigns(:widget)
    assert_equal 2, widget.versions.length
    assert_equal 153, widget.versions.last.whodunnit.to_i
  end
end

