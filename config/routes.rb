require 'api_constraints'

Ce2::Application.routes.draw do

  default_url_options :host => "civicevolution.org"

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :comments do
        get 'history', :on => :member
        post 'accept', :on => :member
        post 'decline', :on => :member
        post 'assign_themes', on: :member
        post 'update_comment_order', on: :member
      end

    end
    #scope module: :v2, constraints: ApiConstraints.new(version: 2, default: true) do
    #  resources :products
    #end
  end

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :conversations do
        post 'update_comment_order', on: :member
        get 'title', on: :member
        post 'title', on: :member
        post 'privacy', on: :member
        post 'tags', on: :member
        post 'schedule', on: :member
        post 'publish', on: :member
        get 'guest_posts', on: :member
        get 'pending_comments', on: :member
        get 'flagged_comments', on: :member
        get 'participants_roles', on: :member
        get 'invited_guests', on: :member
        post 'update_role', on: :member
        get 'stats', on: :member
        get 'theme_data', on: :member
        get 'parked_comments', on: :member
        get 'group_data', on: :member
        get 'themes', on: :member
        get 'firebase_token', on: :member
        resources :comments, shallow: true
      end
    end
    #scope module: :v2, constraints: ApiConstraints.new(version: 2, default: true) do
    #  resources :products
    #end
  end

  post "api/conversations/:id/bookmark" => "api/v1/bookmarks#create", format: :json, type: 'Conversation'
  delete "api/conversations/:id/bookmark" => "api/v1/bookmarks#destroy", format: :json, type: 'Conversation'
  post "api/comments/:id/bookmark" => "api/v1/bookmarks#create", format: :json, type: 'Comment'
  delete "api/comments/:id/bookmark" => "api/v1/bookmarks#destroy", format: :json, type: 'Comment'

  post "api/conversations/:id/flag_item" => "api/v1/flagged_items#create", format: :json, type: 'Conversation'
  post "api/comments/:id/flag_item" => "api/v1/flagged_items#create", format: :json, type: 'Comment'

  post "api/conversations/:id/invite" => "api/v1/invites#create", format: :json

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :guest_posts, only: [ ] do
        post 'accept', :on => :member
        post 'decline', :on => :member
      end
    end
  end

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :flagged_items, only: [ ] do
        post 'mark_flagged_as', on: :member
      end
    end
  end

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :attachments do
        get 'history', :on => :member
      end

    end
    #scope module: :v2, constraints: ApiConstraints.new(version: 2, default: true) do
    #  resources :products
    #end
  end


  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :notification_requests
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

  match "comments/:comment_id/rate/:rating" => "api/v1/comments#rate", constraints: {comment_id: /\d+/, rating: /\d+/}, via: [:post, :get], format: :json

  get "conversation/index"

  #get '/' => 'home#home', constraints: { subdomain: 'www' }
  #get '/' => 'home#home', constraints: { subdomain: '' }
  get '/home' => 'home#home'
  root :to => "home#app"

  post 'follow' => 'contacts#follow'

  post 'contact_us' => 'contacts#send_message'

  post 'activity_report' => 'api/v1/activity_reports#record'

  get 'unsubscribe/:token' => "subscribes#unsubscribe"

  #root :to => "home#index"
  #root to: "conversations#index"
  
  devise_for :users
  resources :users

  post "api/users/photo" => "api/v1/profiles#upload_photo", format: :json

  post "api/reports/image" => "api/v1/reports#upload_report", format: :json

  # access ui templates that are normally stored in js file but cleared by dev's clear cache command
  get '/template/*path/*file.*pre', to: redirect("/assets/ui/%{path}/%{file}.%{pre}")

  match '(errors)/:status', to: 'errors#show', constraints: {status: /\d{3}/}, via: :all

  get 'invites/:invite_code/:munged_title', to: 'invites#lookup'
  post 'invites/confirmed', to: 'invites#confirmed'

  get 'guest_confirmation/:guest_confirmation_code', to: 'guest_confirmations#lookup'
  post 'guest_confirmation/confirmed', to: 'guest_confirmations#confirmed'

  post 'autosave', to: 'api/v1/autosave#save'
  get 'load_autosaved', to: 'api/v1/autosave#load'
  post 'clear_autosaved', to: 'api/v1/autosave#clear'

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :theme_points, only: [ ] do
        post 'save', on: :member
      end
    end
  end

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :theme_votes, only: [ ] do
        post 'save', on: :member
      end
    end
  end

  get 'api/agendas', to: 'api/v1/agendas#agendas'

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :agendas, only: [ ] do
        get 'agenda', on: :member
        get 'agenda_for_component', on: :member
        post 'accept_role', on: :member
        post 'release_role', on: :member
        get 'participant_report', on: :member
        get 'export', on: :member
        get 'import', on: :member
        post 'reset', on: :member
        get 'participant_report_data', on: :member
        get 'conversations', on: :member
        get 'reports', on: :member
        get 'report_data_sets', on: :member
      end
      get 'agendas/:id/link/:link_code/data_set(.:format)', to: 'agendas#data_set'
    end
  end



  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :components, only: [ ], controller: 'agenda_components' do
        get 'data', on: :member
        get 'results', on: :member
        get 'participant_worksheet', on: :member
      end
    end
  end

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :reports, except: [ ] do
        #delete 'delete', on: :member
      end
    end
  end


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