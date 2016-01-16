require 'test_helper'

class EnabledForControllerTest < ActionController::TestCase
  tests ArticlesController

  context "`PaperTrail.enabled? == true`" do
    should 'enabled_for_controller?.should == true' do
      assert_equal true, PaperTrail.enabled?
      post :create, params_wrapper(article: { title: 'Doh', content: FFaker::Lorem.sentence })
      assert_not_nil assigns(:article)
      assert_equal true, PaperTrail.enabled_for_controller?
      assert_equal 1, assigns(:article).versions.length
    end
  end

  context "`PaperTrail.enabled? == false`" do
    setup do
      PaperTrail.enabled_in_current_thread = false
    end

    should 'enabled_for_controller?.should == false' do
      assert_equal false, PaperTrail.enabled?
      post :create, params_wrapper(article: { title: 'Doh', content: FFaker::Lorem.sentence })
      assert_equal false, PaperTrail.enabled_for_controller?
      assert_equal 0, assigns(:article).versions.length
    end

    teardown do
      PaperTrail.enabled_in_current_thread = true
    end
  end
end
