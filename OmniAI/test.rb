#!/usr/bin/env ruby
# File: test.rb
# Desc: getting the feel for omniai

ENV['ANTHROPIC_API_KEY']  = '123'
ENV['GOOGLE_API_KEY']     = '456'
ENV['MISTRAL_API_KEY']    = '489'
#
ENV['LOCALAI_API_KEY']    = '987'
ENV['LOCALAI_HOST']       = 'http://localhost:8080'

ENV['OLLAMA_API_KEY']     = '654'
ENV['OLLAMA_HOST']        = 'http://localhost:11434'

require 'debug_me'
include DebugMe

require 'omniai'
require 'omniai/anthropic'
require 'omniai/google'
require 'omniai/mistral'
require 'omniai/openai'

module OmniAI
  module LocalAI
    class Client
      def initialize(**kwargs)
        kwargs[:host]     ||= ENV.fetch('LOCALAI_HOST','http://localhost:8080')
        kwargs[:api_key]  ||= ENV.fetch('LOCALAI_API_KEY')
        @openai_client      = OmniAI::OpenAI::Client.new(**kwargs)
      end

      # Forward all missing instance methods to the internal OpenAI client
      def method_missing(method, *args, &block)
        if @openai_client.respond_to?(method)
          @openai_client.send(method, *args, &block)
        else
          super
        end
      end

      # Forward all missing class methods to the internal OpenAI client's class
      def self.method_missing(method, *args, &block)
        if OmniAI::OpenAI::Client.respond_to?(method)
          OmniAI::OpenAI::Client.send(method, *args, &block)
        else
          super
        end
      end
    end
  end
end


module OmniAI
  module Ollama
    class Client
      def initialize(**kwargs)
        kwargs[:host]     ||= ENV.fetch('OLLAMA_HOST','http://localhost:11434')
        kwargs[:api_key]  ||= ENV.fetch('OLLAMA_API_KEY')
        @openai_client      = OmniAI::OpenAI::Client.new(**kwargs)
      end

      # Forward all missing instance methods to the internal OpenAI client
      def method_missing(method, *args, &block)
        if @openai_client.respond_to?(method)
          @openai_client.send(method, *args, &block)
        else
          super
        end
      end

      # Forward all missing class methods to the internal OpenAI client's class
      def self.method_missing(method, *args, &block)
        if OmniAI::OpenAI::Client.respond_to?(method)
          OmniAI::OpenAI::Client.send(method, *args, &block)
        else
          super
        end
      end
    end
  end
end


%w[claude-3.5 gemini-2 mistral gpt-4o local-llm llama-3 codestral].each do | model |
client  = case model
          # Hit the remote APIs
          when /claude/   then OmniAI::Anthropic::Client.new
          when /gemini/   then OmniAI::Google::Client.new
          when /mistral/  then OmniAI::Mistral::Client.new
          when /gpt/      then OmniAI::OpenAI::Client.new
          
          # Keep everything on the localhost
          when /local/      then OmniAI::LocalAI::Client.new
          when /llama/      then OmniAI::Ollama::Client.new
          when /codestral/  then OmniAI::Ollama::Client.new
          else
            # Error: Unknown model prefix
            nil
          end

debug_me{[
  :model,
  "client.class.name"
]}

end

__END__

#################################################
# Logging the request / response is configurable by passing a logger into any client:

require 'omniai/openai'
require 'logger'

logger = Logger.new(STDOUT)
client = OmniAI::Example::Client.new(logger:)

#################################################
# Timeouts are configurable by passing a `timeout` an integer duration for the request / response of any APIs using:

require 'omniai/openai'
require 'logger'

logger = Logger.new(STDOUT)
client = OmniAI::OpenAI::Client.new(timeout: 8) # i.e. 8 seconds

#################################################
# Timeouts are also be configurable by passing a `timeout` hash with `timeout` / `read` / `write` / `keys using:

require 'omniai/openai'
require 'logger'

logger = Logger.new(STDOUT)
client = OmniAI::OpenAI::Client.new(timeout: {
  read: 2, # i.e. 2 seconds
  write: 3, # i.e. 3 seconds
  connect: 4, # i.e. 4 seconds
})


#################################################
### Chat - Clients that support chat (e.g. Anthropic w/ "Claude", Google w/ "Gemini", Mistral w/ "LeChat", OpenAI w/ "ChatGPT", etc) generate completions using the following calls:

#### Completions using Single Message

completion = client.chat('Tell me a joke.')
completion.choice.message.content # '...'


#### Completions using Multiple Messages

messages = [
  {
    role: OmniAI::Chat::Role::SYSTEM,
    content: 'You are a helpful assistant with an expertise in geography.',
  },
  'What is the capital of Canada?'
]
completion = client.chat(messages, model: '...', temperature: 0.7, format: :json)
completion.choice.message.content  # '...'


#### Completions using Real-Time Streaming

stream = proc do |chunk|
  print(chunk.choice.delta.content) # '...'
end
client.chat('Tell me a joke.', stream:)



#################################################
### Transcribe - Clients that support transcribe (e.g. OpenAI w/ "Whisper") convert recordings to text via the following calls:

#### Transcriptions with Path

transcription = client.transcribe("example.ogg")
transcription.text # '...'


#### Transcriptions with Files

File.open("example.ogg", "rb") do |file|
  transcription = client.transcribe(file)
  transcription.text # '...'
end


#################################################
### Speak - Clients that support speak (e.g. OpenAI w/ "Whisper") convert text to recordings via the following calls:

#### Speech with Stream

File.open('example.ogg', 'wb') do |file|
  client.speak('The quick brown fox jumps over a lazy dog.', voice: 'HAL') do |chunk|
    file << chunk
  end
end


#### Speech with File

tempfile = client.speak('The quick brown fox jumps over a lazy dog.', voice: 'HAL')
tempfile.close
tempfile.unlink

#################################################
# Usage with LocalAI
# 
# LocalAI offers built in compatability with the OpenAI specification. To initialize a client that points to a Ollama change the host accordingly:

client = OmniAI::OpenAI::Client.new(host: 'http://localhost:8080', api_key: nil)

# For details on installation or running LocalAI see the getting started tutorial.


#################################################
# Usage with Ollama
# 
# Ollama offers built in compatability with the OpenAI specification. To initialize a client that points to a Ollama change the host accordingly:

client = OmniAI::OpenAI::Client.new(host: 'http://localhost:11434', api_key: nil)

# For details on installation or running Ollama checkout the project README.



#################################################




