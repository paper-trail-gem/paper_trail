class ArticlesController < ApplicationController
  def create
    if PaperTrail.active_record_protected_attributes?
      @article = Article.create params[:article]
    else
      @article = Article.create params.require(:article).permit!
    end
    head :ok
  end

  def current_user
    'foobar'.tap do |string|
      # Support ruby 1.8, in which `String` responds to `id`.
      string.class_eval { undef_method(:id) } if RUBY_VERSION < '1.9'
    end
  end
end
