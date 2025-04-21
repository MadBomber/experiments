#!/usr/bin/env ruby
# experiments/ai_misc/openai_list_models.rb
#
#
# curl https://api.openai.com/v1/models \
#   -H "Authorization: Bearer $OPENAI_API_KEY"


require 'amazing_print'
require 'debug_me'
include DebugMe

require 'faraday'

OPENAI_API_KEY = ENV['OPENAI_API_KEY']

def list_models
  url = "https://api.openai.com/v1/models"

  response = Faraday.get(url) do |req|
    req.headers['Authorization'] = "Bearer #{OPENAI_API_KEY}"
  end

  return response
end

r = list_models

if 200 == r.status
  puts r.body
else
  puts "Error: wtatus was #{r.status}"
  puts ap r
end
