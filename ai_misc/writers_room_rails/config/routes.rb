Rails.application.routes.draw do
  passwordless_for :users

  root "projects#index"

  resources :actors
  resources :characters

  resources :projects do
    resources :scenes, shallow: true do
      resources :scene_runs, only: [ :create, :show ]
      member do
        patch :submit
        patch :release
        patch :reject
      end
    end
    resources :stories
    resources :castings
    resources :character_arcs
    resources :research_materials
    resources :beats
  end

  resources :scenes, only: [] do
    resources :scene_comments, only: [ :create, :destroy ]
  end

  resources :users, only: [ :index, :show, :edit, :update ]
  resources :imports, only: [ :new, :create ]
  resources :exports, only: [ :show ]

  # PWA
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
