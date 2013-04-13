require 'api_constraints'

Ce2::Application.routes.draw do

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :comments
    end
    #scope module: :v2, constraints: ApiConstraints.new(version: 2, default: true) do
    #  resources :products
    #end
  end
  

  #resources :comments


  get "conversation/index"

  #authenticated :user do
  #  root :to => 'home#index'
  #end
  #root :to => "home#index"
  root to: "conversation#index"
  
  devise_for :users
  resources :users


end