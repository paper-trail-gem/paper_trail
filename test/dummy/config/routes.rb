Dummy::Application.routes.draw do
  resources :articles, :only => [:create]
  resources :widgets, :only => [:create, :update, :destroy]
end
