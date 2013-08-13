require 'test_helper'
require 'sinatra/base'

# --- Tests for modular `Sinatra::Base` style ----
class BaseApp < Sinatra::Base
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => File.expand_path('../../dummy/db/test.sqlite3', __FILE__))
  register PaperTrail::Sinatra

  get '/test' do
    w = Widget.create!(:name => 'foo')
    'Hello'
  end

  def current_user
    'foobar'
  end
end

class PaperTrailModularSinatraTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    @app ||= BaseApp
  end

  test 'baseline' do
    assert_nil Widget.first
    assert_nil Widget.create.versions.first.whodunnit
  end

  context "`PaperTrail::Sinatra` in a `Sinatra::Base` application" do
  
    should "sets the `user_for_paper_trail` from the `current_user` method" do
      get '/test'
      assert_equal 'Hello', last_response.body
      widget = Widget.first
      assert_not_nil widget
      assert_equal 1, widget.versions.size
      assert_equal 'foobar', widget.versions.first.whodunnit
    end

  end
end

# --- Tests for non-modular `Sinatra::Application` style ----
class Sinatra::Application
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => File.expand_path('../../dummy/db/test.sqlite3', __FILE__))

  get '/test' do
    w = Widget.create!(:name => 'foo')
    'Hello'
  end

  def current_user
    'raboof'
  end
end

class PaperTrailSinatraTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  test 'baseline' do
    assert_nil Widget.first
    assert_nil Widget.create.versions.first.whodunnit
  end

  context "`PaperTrail::Sinatra` in a `Sinatra::Application` application" do

    def app
      @app ||= BaseApp
    end

    should "sets the `user_for_paper_trail` from the `current_user` method" do
      get '/test'
      assert_equal 'Hello', last_response.body
      widget = Widget.first
      assert_not_nil widget
      assert_equal 1, widget.versions.size
      assert_equal 'raboof', widget.versions.first.whodunnit
    end

  end
end
