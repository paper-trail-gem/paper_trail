class ArticlesController < ApplicationController
  def create
    @article = Article.create article_params
    head :ok
  end

  def current_user
    'foobar'
  end

  private

  def article_params
    if PaperTrail.active_record_protected_attributes?
      params[:article]
    else
      params.require(:article).permit!
    end
  end
end
