Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :posts, only: [ :index ]

  root to: "posts#index"
  get "up" => "rails/health#show", :as => :rails_health_check

  # route spéciale pour le oauth de atproto
  get("/oauth/client-metadata.json",
    to: proc { |env|
          [
            200,
            { "Content-Type" => "application/json" },
            [ File.read(Rails.public_path.join("oauth/client-metadata.json")) ]
          ]
        })

  get "auth/:provider/callback", to: "sessions#create"
end
