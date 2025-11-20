#!/usr/bin/env ruby
# @/experiments/raix/example_tools.rb
#
# FIXME: This example does not work
#

require 'debug_me'
include DebugMe

require 'raix'


Raix.configure do |config|
  config.openai_client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
end


# first example raix readme works

class WhatIsTheWeather
  include Raix::ChatCompletion
  include Raix::FunctionDispatch

  function( :check_weather, 
            "Check the weather for a location", 
            location: { type: "string" }
    ) do |arguments|
      "The weather in #{arguments[:location]} is hot and sunny"
    end
end


# subject = WhatIsTheWeather.new

# subject.transcript << { user: "What is the weather in Zipolite, Oaxaca?" }

# response = subject.chat_completion(openai: "gpt-4o", loop: true)

# debug_me{[
#   :response
# ]}

###########################################




# This the 2nd example from
# the raix readme.
class MultipleToolExample
  include Raix::ChatCompletion
  include Raix::FunctionDispatch

  function(
    :first_tool,
    "first tool"
  ) do # |arguments|
      "Result from first tool"
    end

  function(
    :second_tool,
    "second tool"
  ) do # |arguments|
      "Result from second tool"
    end
end

example = MultipleToolExample.new
example.transcript << { user: "Please use both the first tool and second tool without arguments" }
results = example.chat_completion(openai: "gpt-4o")

debug_me{[
  :results
]}

