#!/usr/bin/env ruby
# experiments/OmniAI/examples/text.rb

require_relative 'common'

models  = [ 
  'gpt-3.5-turbo',        # OpenAI
  'claude-2.1',           # Anthropic
  'gemini-1.5-flash',     # Google
  'mistral-large-latest', # Mistral - La Platform
]
clients = []

models.each do |model|
  clients << MyClient.new(model)
end


title "Default Configuration Response to 'hello'"

clients.each do |c|
  puts "\nModel: #{c.model} (#{c.model_type})  Provider: #{c.provider}"
  puts c.chat('hello')
end

###################################

MyClient.configure do |o|
  o.return_raw = true
end

raw_clients = []

models.each do |model|
  raw_clients << MyClient.new(model)
end

puts
title "Raw Configuration Response to 'hello'"

raw_clients.each do |c|
  puts "\nModel: #{c.model} (#{c.model_type})  Provider: #{c.provider}"
  puts c.chat('hello').pretty_inspect
end

puts

