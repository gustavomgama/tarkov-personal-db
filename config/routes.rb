Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Local-only reference DB: full access in dev/test, loopback-only elsewhere
  # (a Kamal/proxied deploy would mask remote_ip, hence the env check).
  constraints ->(req) { !Rails.env.production? || req.local? } do
    root "items#index"

    resources :items, only: %i[index show], param: :slug
    resources :tasks, only: %i[index show]
    resources :traders, only: %i[index show]

    get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
    get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  end
end
