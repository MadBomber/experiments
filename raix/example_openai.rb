#!/usr/bin/env ruby 
# example_openai.rb

require 'raix'

require 'debug_me'
include DebugMe

Raix.configuration.openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

# This is Example 1 from the raix README file

class MeaningOfLife
  include Raix::ChatCompletion
  model = "gpt-4o-mini"
end

ai = MeaningOfLife.new
ai.transcript << { user: "What is the meaning of life?" }

response = ai.chat_completion(openai: 'gpt-4o')

debug_me{[
  :ai,
  :response
]}

=begin
=> "The question of the meaning of life is one of the most profound and enduring inquiries in philosophy, religion, and science.
    Different perspectives offer various answers..."
=end

