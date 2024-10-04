#!/usr/bin/env ruby 
# example_1.rb

require 'raix'

require 'debug_me'
include DebugMe

Raix.configuration.openrouter_client = OpenRouter::Client.new

OpenRouter.configure do |config|
  config.access_token = ENV.fetch("OPEN_ROUTER_API_KEY")
  # TODO: assume you configure which model/provider to use here
end


# This is Example 1 from the raix README file

class MeaningOfLife
  include Raix::ChatCompletion
end

ai = MeaningOfLife.new
ai.transcript << { user: "What is the meaning of life?" }

response = ai.chat_completion

debug_me{[
  :ai,
  :response
]}

=begin
=> "The question of the meaning of life is one of the most profound and enduring inquiries in philosophy, religion, and science.
    Different perspectives offer various answers..."
=end

