require 'api_constraints'

Ce2::Application.routes.draw do

  default_url_options :host => "civicevolution.org"

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :comments do
        get 'history', :on => :member
      end

    end
    #scope module: :v2, constraints: ApiConstraints.new(version: 2, default: true) do
    #  resources :products
    #end
  end

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :conversations
    end
    #scope module: :v2, constraints: ApiConstraints.new(version: 2, default: true) do
    #  resources :products
    #end
  end


  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      #resources :users
      get 'users/user'
    end
  end
  #get '/api/users(.:format)',            api/v1/comments#index {:format=>"json"}

  #resources :comments

  get "issues/:issue_id" => "issues#show", constraints: {issue_id: /\d+/}
  get "issues/:munged_title" => "issues#show", constraints: {munged_title: /[\w&-]+/}

  get "conversation/index"

  #authenticated :user do
  #  root :to => 'home#index'
  #end
  #root :to => "home#index"
  root to: "conversation#index"
  
  devise_for :users
  resources :users

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

end