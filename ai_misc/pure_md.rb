#!/usr/bin/env ruby
# experiments/ai_misc/pure_md.rb
#
#
# curl \
# -H "x-puremd-api-token: $PUREMD_API_KEY" \
# https://pure.md/https://ai.google.dev/gemini-api/docs/models

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'faraday'

PUREMD_API_KEY = ENV['PUREMD_API_KEY']

def get(url)
  puremd_url = "https://pure.md/#{url}"

  response = Faraday.get(puremd_url) do |req|
    req.headers['x-puremd-api-token'] = PUREMD_API_KEY
  end

  return response
end

r = get("https://docs.anthropic.com/en/docs/about-claude/models/all-models")

if 200 == r.status
  puts r.body
else
  puts "Error: wtatus was #{r.status}"
  puts ap r
end
