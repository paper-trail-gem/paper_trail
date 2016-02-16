# Our ActiveRecord 5 gemfile (see `Appraisals`) must use `rack 2.0.0.alpha`
# which renames several files that sinatra 1 depended on. Until there is
# a released version of sinatra that supports `rack 2.0.0.alpha`, we
# must exclude sinatra from our test suite. This is done in two files:
#
# - test/functional/sinatra_test.rb
# - test/functional/modular_sinatra_test.rb
#
if Gem::Version.new(Rack.release) < Gem::Version.new("2.0.0.alpha")
  require 'test_helper'
  # require 'sinatra/main'

  # --- Tests for non-modular `Sinatra::Application` style ----
  module Sinatra
    class Application
      configs = YAML.load_file(File.expand_path('../../dummy/config/database.yml', __FILE__))
      ActiveRecord::Base.configurations = configs
      ActiveRecord::Base.establish_connection(:test)

      # We shouldn't actually need this line if I'm not mistaken but the tests
      # seem to fail without it ATM
      register PaperTrail::Sinatra

      get '/test' do
        Widget.create!(:name => 'bar')
        'Hai'
      end

      def current_user
        @current_user ||= OpenStruct.new(id: 'raboof')
      end
    end
  end

  class SinatraTest < ActionDispatch::IntegrationTest
    include Rack::Test::Methods

    def app
      @app ||= Sinatra::Application
    end

    test 'baseline' do
      assert_nil Widget.create.versions.first.whodunnit
    end

    context "`PaperTrail::Sinatra` in a `Sinatra::Application` application" do
      should "sets the `user_for_paper_trail` from the `current_user` method" do
        get '/test'
        assert_equal 'Hai', last_response.body
        widget = Widget.last
        assert_not_nil widget
        assert_equal 'bar', widget.name
        assert_equal 1, widget.versions.size
        assert_equal 'raboof', widget.versions.first.whodunnit
      end
    end
  end
end
