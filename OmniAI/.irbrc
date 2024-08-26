# experiments/OmniAI/.irbrc

require_relative 'my_client'

MyClient.configure do |c|
  c.return_raw = true
end
