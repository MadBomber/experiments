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

DebugMeDefaultOptions = {
  tag:    'DEBUG',  # A tag to prepend to each output line
  time:   true,     # Include a time-stamp in front of the tag
  strftime:  '%Y-%m-%d %H:%M:%S.%6N', # timestamp format
  header: true,     # Print a header string before printing the variables
  levels: 0,        # Number of additional backtrack entries to display
  skip1:  false,    # skip 1 lines between different outputs
  skip2:  true,     # skip 2 lines between different outputs
  lvar:   true,     # Include local variables
  ivar:   true,     # Include instance variables in the output
  cvar:   true,     # Include class variables in the output
  cconst: true,     # Include class constants
  logger: nil,      # Pass in an instance of logger class like Rails.logger
                    # must respond_to? :debug
  file:   $stdout   # The output file
}




require 'omniai'
require 'omniai/anthropic'
require 'omniai/google'
require 'omniai/mistral'
require 'omniai/openai'

# Sub-class the OmniAI::OpenAI::Client for both
# LocalAI and Ollama both of which use the same API
# as OpenAI but can be processed on the localhost or
# some other LAN-based system.  Using LocalAI and Ollama
# there is no need to ship your private information
# out to cloud providers.

module OmniAI
  module LocalAI
    class Client < OmniAI::OpenAI::Client
      def initialize(**kwargs)
        kwargs[:host]     ||= ENV.fetch('LOCALAI_HOST','http://localhost:8080')
        kwargs[:api_key]  ||= ENV.fetch('LOCALAI_API_KEY', nil)
        super(**kwargs)
      end
    end
  end

  module Ollama
    class Client < OmniAI::OpenAI::Client
      def initialize(**kwargs)
        kwargs[:host]     ||= ENV.fetch('Ollama_HOST','http://localhost:11434')
        kwargs[:api_key]  ||= ENV.fetch('OLLAMA_API_KEY', nil)
        super(**kwargs)
      end
    end
  end
end


%w[
    claude-3.5 gemini-2 mistral gpt-4o 
    local-llm llama-3 
    codestral
].each do |model|
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
    :client,
    :model,
    'client.class',
  ]}

end


puts "\n"*3
puts "="*64
puts "== individual method examples"

#################################################
# Logging the request / response is configurable by passing a logger into any client:

# require 'omniai/openai'
require 'logger'

logger = Logger.new(STDOUT)
client = OmniAI::OpenAI::Client.new(logger:)

debug_me('OpenAI with logger'){[
  :client
]}

#################################################
# Timeouts are configurable by passing a `timeout` an integer duration for the request / response of any APIs using:

# require 'omniai/openai'
require 'logger'

logger = Logger.new(STDOUT)
client = OmniAI::OpenAI::Client.new(timeout: 8) # i.e. 8 seconds

debug_me('OpenAI with logger and timeout'){[
  :client
]}



#################################################
# Timeouts are also be configurable by passing a `timeout` hash with `timeout` / `read` / `write` / `keys using:

# require 'omniai/openai'
require 'logger'

logger = Logger.new(STDOUT)
client = OmniAI::OpenAI::Client.new(timeout: {
  read: 2, # i.e. 2 seconds
  write: 3, # i.e. 3 seconds
  connect: 4, # i.e. 4 seconds
})


debug_me('OpenAI with logger and expanded timeout'){[
  :client
]}

#################################################
### Chat - Clients that support chat (e.g. Anthropic w/ "Claude", Google w/ "Gemini", Mistral w/ "LeChat", OpenAI w/ "ChatGPT", etc) generate completions using the following calls:

#### Completions using Single Message

completion = client.chat('Tell me a joke.')


debug_me('OpenAI.chat'){[
  :completion
]}


puts completion.choice.message.content # '...'


puts <<~HERE

===============
== HERE ==
==========

HERE

#### Completions using Multiple Messages

messages = [
  {
    role: OmniAI::Chat::Role::SYSTEM,
    content: 'You are a helpful assistant with an expertise in geography.',
  },
  'What is the capital of Canada?'
]
completion = client.chat(messages, model: 'gpt-4o-2024-05-13', temperature: 0.7, format: :json)

debug_me('OpenAI.chat'){[
  :message,
  :completion
]}

puts completion.choice.message.content  # '...'


#### Completions using Real-Time Streaming

debug_me("streaming a chat")

stream = proc do |chunk|
  print(chunk.choice.delta.content) # '...'
end
client.chat('Tell me a joke.', stream:)



#################################################
### Transcribe - Clients that support transcribe (e.g. OpenAI w/ "Whisper") convert recordings to text via the following calls:

#### Transcriptions with Path

debug_me("transcribe is disabled")

# transcription = client.transcribe("example.ogg")
# transcription.text # '...'


#### Transcriptions with Files

debug_me("transcribe-2 is disabled")

# File.open("example.ogg", "rb") do |file|
#   transcription = client.transcribe(file)
#   transcription.text # '...'
# end


#################################################
### Speak - Clients that support speak (e.g. OpenAI w/ "Whisper") convert text to recordings via the following calls:

#### Speech with Stream

debug_me("transcribe-3 is disabled")

# File.open('example.ogg', 'wb') do |file|
#   client.speak('The quick brown fox jumps over a lazy dog.', voice: 'HAL') do |chunk|
#     file << chunk
#   end
# end


#### Speech with File

debug_me('OpenAI.speak')

tempfile = client.speak('The quick brown fox jumps over a lazy dog.', voice: 'HAL')
tempfile.close
tempfile.unlink

#################################################
# Usage with LocalAI
# 
# LocalAI offers built in compatability with the OpenAI specification. To initialize a client that points to a Ollama change the host accordingly:

client = OmniAI::LocalAI::Client.new

debug_me('LocalAI'){[
  :client
]}

# For details on installation or running LocalAI see the getting started tutorial.


#################################################
# Usage with Ollama
# 
# Ollama offers built in compatability with the OpenAI specification. To initialize a client that points to a Ollama change the host accordingly:

client = OmniAI::Ollama::Client.new

debug_me('Ollama'){[
  :client
]}

# For details on installation or running Ollama checkout the project README.



#################################################




