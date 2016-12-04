class ArticlesController < ApplicationController
  def create
    @article = Article.create article_params
    head :ok
  end

  def current_user
    "foobar"
  end

  private

  def article_params
    params.require(:article).permit!
  end
end
