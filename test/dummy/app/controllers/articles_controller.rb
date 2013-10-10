class ArticlesController < ApplicationController
  def create
    if PaperTrail.active_record_protected_attributes?
      @article = Article.create params[:article]
    else
      @article = Article.create params.require(:article).permit!
    end
    head :ok
  end
end
