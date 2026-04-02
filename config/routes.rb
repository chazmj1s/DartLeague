# config/routes.rb
Rails.application.routes.draw do
  root "home#index"

  resources :players

  resources :matches do
    member do
      post :finalize
      post :reassign
    end

    resources :absences, only: %i[create destroy]

    resources :games, only: %i[update] do
      member do
        patch :complete
      end
    end
  end

  # Health check for load balancers / uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check
end
