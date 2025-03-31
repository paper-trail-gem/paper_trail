# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Articles management", order: :defined, type: :request do
  let(:valid_params) { { article: { title: "Doh", content: FFaker::Lorem.sentence } } }

  context "with versioning disabled" do
    specify { expect(PaperTrail).not_to be_enabled }

    it "does not create a version" do
      expect(PaperTrail.request).to be_enabled
      expect {
        post articles_path, params: valid_params
      }.not_to change(PaperTrail::Version, :count)
    end
  end

  with_versioning do
    let(:article) { Article.last }

    context "when `current_user` method returns a `String`" do
      it "sets that value as the `whodunnit`" do
        expect {
          post articles_path, params: valid_params
        }.to change(PaperTrail::Version, :count).by(1)
        expect(article.title).to eq("Doh")
        expect(article.versions.last.whodunnit).to eq("foobar")
      end
    end
  end
end
