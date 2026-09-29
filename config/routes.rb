Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "/login", to: "sessions#create"
  post "/webhooks/payments", to: "payment_webhooks#create"

  namespace :api do
    namespace :v1 do
      resources :products, only: [ :index, :create ]
      resources :warehouses, only: [ :index ]
      resources :stock_items, only: [ :index ]
      resources :orders, only: [ :index, :create ] do
        member do
          post :pay
          post :ship
          post :cancel
        end
      end
    end
  end
end
