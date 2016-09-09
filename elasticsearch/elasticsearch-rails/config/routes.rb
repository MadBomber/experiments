
Rails.application.routes.draw do
  root to: 'articles#index'
  resources :articles
  get "search", to: "search#search"
end
