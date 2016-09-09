
Rails.application.routes.draw do
  root to: 'articles#index'
  resources :articles
  get "search", to: "search#search"
  get 'search/typeahead/:term' => 'search#typeahead'
end
