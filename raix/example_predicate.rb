#!/usr/bin/env ruby
# example_predicate.rb

require 'debug_me'
include DebugMe

require 'active_support'
require 'raix'

Raix.configure do |config|
  config.openai_client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
end

class Question
  include Raix::Predicate

  yes? do |explanation|
    puts "Affirmative: #{explanation}"
  end

  no? do |explanation|
    puts "Negative: #{explanation}"
  end

  maybe? do |explanation|
    puts "Uncertain: #{explanation}"
  end
end

question = Question.new
question.ask("Is Ruby a programming language?", openai: "gpt-4o")
