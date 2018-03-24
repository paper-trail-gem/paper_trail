# frozen_string_literal: true

require "spec_helper"

RSpec.describe ArticlesController, type: :controller do
  describe "PaperTrail.request.enabled?" do
    context "PaperTrail.enabled? == true" do
      before { PaperTrail.enabled = true }

      it "returns true" do
        expect(PaperTrail.enabled?).to eq(true)
        post :create, params_wrapper(article: { title: "Doh", content: FFaker::Lorem.sentence })
        expect(assigns(:article)).not_to be_nil
        expect(PaperTrail.request.enabled?).to eq(true)
        expect(assigns(:article).versions.length).to eq(1)
      end

      after { PaperTrail.enabled = false }
    end

    context "PaperTrail.enabled? == false" do
      it "returns false" do
        expect(PaperTrail.enabled?).to eq(false)
        post :create, params_wrapper(article: { title: "Doh", content: FFaker::Lorem.sentence })
        expect(PaperTrail.request.enabled?).to eq(false)
        expect(assigns(:article).versions.length).to eq(0)
      end
    end
  end
end
