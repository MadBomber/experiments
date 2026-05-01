#!/usr/bin/env ruby
# experiments/ai_misc/xai.rb

require 'pathname'
HERE        = Pathname.pwd
MODELS_FILE = File.expand_path('xai_models.json', HERE)

require 'debug_me'
include DebugMe

XAI_BASE_URL  = ENV.fetch('XAI_BASE_URL', 'https://api.xai.com/v1')
XAI_API_KEY   = ENV.fetch('XAI_API_KEY', 'you_need_a_key')


=begin
# This works ...
#
require 'openai'

client = OpenAI::Client.new(
  access_token: XAI_API_KEY,
  uri_base:     XAI_BASE_URL
)

# Use the client manually if needed
response = client.chat(
  parameters: {
    model: 'grok-2-latest',
    messages: [{ role: 'user', content: 'what is the meaning of xyzzy?' }]
  }
)

debug_me{[
  :response
]}

puts response.dig('choices', 0, 'message', 'content')
=end

require 'ruby_llm'

module RubyLLM
  module Providers
    module OpenAI
      def api_base
        XAI_BASE_URL
      end
    end
  end

  class Models
    class << self
      def models_file
        File.join(HERE, 'xai_models.json')
      end
    end
  end
end

# Configure ruby_llm with the API key
RubyLLM.configure do |config|
  config.openai_api_key = XAI_API_KEY
end

# Initialize the chat client with the model
chat = RubyLLM.chat(model: 'grok-2-latest')

# Send the message
response = chat.ask('What is the meaning of xyzzy?')

debug_me { [:response] }

# Output the response content
if response.success?
  puts response.content
else
  puts "Error: #{response.error_message}"
end

__END__


__END__

curl $XAI_BASE_URL/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer $XAI_API_KEY" -d '{
  "messages": [
    {
      "role": "system",
      "content": "You are a test assistant."
    },
    {
      "role": "user",
      "content": "What is the meaning of xyzzy?"
    }
  ],
  "model": "grok-2-latest",
  "stream": false,
  "temperature": 0
}'
