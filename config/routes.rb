Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Auth0
  get "/auth/auth0/callback" => "auth0#callback"
  get "/auth/failure" => "auth0#failure"
  delete "/auth/logout" => "auth0#logout"
  get "/login" => "auth0#login", as: :login

  # Profile
  get "/profile" => "profile#show", as: :profile
  get "/profile/edit" => "profile#edit", as: :edit_profile
  patch "/profile" => "profile#update"

  # Teams
  resources :teams do
    member do
      patch :restore  # For undeleting soft-deleted teams
    end

    # Invitations (Phase 4)
    resources :invitations, only: [ :index, :new, :create, :destroy ]
  end

  # Public invitation acceptance route
  get "invitations/:token", to: "invitations#accept", as: :accept_invitation

  # Team switching (Phase 5)
  post "teams/switch/:team_id", to: "team_switch#update", as: :switch_team,
       constraints: { team_id: /\d+/ }

  # Defines the root path route ("/")
  root "pages#home"
end
