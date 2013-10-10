require 'test_helper'

class EnabledForControllerTest < ActionController::TestCase
  tests ArticlesController

  context "`PaperTrail.enabled? == true`" do
    should 'enabled_for_controller?.should == true' do
      assert PaperTrail.enabled?
      post :create, :article => { :title => 'Doh', :content => Faker::Lorem.sentence }
      assert_not_nil assigns(:article)
      assert PaperTrail.enabled_for_controller?
      assert_equal 1, assigns(:article).versions.length
    end
  end

  context "`PaperTrail.enabled? == false`" do
    setup { PaperTrail.enabled = false }
    
    should 'enabled_for_controller?.should == false' do
      assert !PaperTrail.enabled?
      post :create, :article => { :title => 'Doh', :content => Faker::Lorem.sentence }
      assert !PaperTrail.enabled_for_controller?
      assert_equal 0, assigns(:article).versions.length
    end

    teardown { PaperTrail.enabled = true }
  end

end
