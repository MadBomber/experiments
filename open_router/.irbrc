require 'open_router'


OpenRouter.configure do |config|
  config.access_token = ENV.fetch('OPEN_ROUTER_API_KEY', nil)
end

AI = OpenRouter::Client.new

# Returns an Array of Hash for supported 
# models/providers
Models = AI.models
