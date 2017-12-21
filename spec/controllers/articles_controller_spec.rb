# frozen_string_literal: true

require "spec_helper"

RSpec.describe ArticlesController, type: :controller do
  describe "PaperTrail.enabled_for_controller?" do
    context "PaperTrail.enabled? == true" do
      before { PaperTrail.enabled = true }

      it "returns true" do
        assert PaperTrail.enabled?
        post :create, params_wrapper(article: { title: "Doh", content: FFaker::Lorem.sentence })
        expect(assigns(:article)).not_to be_nil
        assert PaperTrail.enabled_for_controller?
        assert_equal 1, assigns(:article).versions.length
      end

      after { PaperTrail.enabled = false }
    end

    context "PaperTrail.enabled? == false" do
      it "returns false" do
        assert !PaperTrail.enabled?
        post :create, params_wrapper(article: { title: "Doh", content: FFaker::Lorem.sentence })
        assert !PaperTrail.enabled_for_controller?
        assert_equal 0, assigns(:article).versions.length
      end
    end
  end
end
