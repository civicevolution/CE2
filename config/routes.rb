Ce2::Application.routes.draw do
  resources :comments


  get "conversation/index"

  #authenticated :user do
  #  root :to => 'home#index'
  #end
  #root :to => "home#index"
  root to: "conversation#index"
  
  devise_for :users
  resources :users
end