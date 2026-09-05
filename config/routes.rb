Rails.application.routes.draw do
  resources :items, only: [:index, :show]
  resources :tasks, only: [:index, :show]

  get "up" => "rails/health#show", as: :rails_health_check

  root "items#index"
end
