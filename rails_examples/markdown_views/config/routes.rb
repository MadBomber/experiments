Rails.application.routes.draw do
  get '/docs/*id' => 'pages#show', :as => :page, :format => false
end
