require 'rails_helper'

describe "Articles management", :type => :request, :order => :defined do
  let(:valid_params) { { :article => { :title => 'Doh', :content => Faker::Lorem.sentence } } }

  context "versioning disabled" do
    specify { expect(PaperTrail).not_to be_enabled }

    it "should not create a version" do
      expect(PaperTrail).to be_enabled_for_controller
      expect { post(articles_path, valid_params) }.to_not change(PaperTrail::Version, :count)
    end

    it "should not leak the state of the `PaperTrail.enabled_for_controller?` into the next test" do
      expect(PaperTrail).to be_enabled_for_controller
    end
  end

  with_versioning do
    let(:article) { Article.last }

    context "`current_user` method returns a `String`" do
      it "should set that value as the `whodunnit`" do
        expect { post articles_path, valid_params }.to change(PaperTrail::Version, :count).by(1)
        expect(article.title).to eq('Doh')
        expect(article.versions.last.whodunnit).to eq('foobar')
      end
    end
  end
end
