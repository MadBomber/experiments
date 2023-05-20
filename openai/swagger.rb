#!/usr/bin/env ruby


require 'boxcars'  # Boxcars is a gem that enables you to create new systems with AI composability. Inspired by python langchain.

require 'amazing_print'     # Pretty print Ruby objects with proper indentation and colors
require 'tty-progressbar'   # A flexible and extensible progress bar for terminal applications.

# Use the Swagger Pet Store server as an example

swagger_url = "https://petstore.swagger.io/v2/swagger.json"
sbox        = Boxcars::Swagger.new(swagger_url: swagger_url, context: "API_token: secret-key")
my_pet      = "40010473" # FIXME: (outdated) example id for below


prompts = []

prompts << "List the APIs for Pets?"
prompts << "Using the find by status api, how many pets are available?"
prompts << "What is the current store inventory?"

# FIXME:  The my_pet ID is outdated so these prompts
#         result in a 404 not found http error
#
# prompts << "I was watching pet with id #{my_pet}. Has she sold?"
# prompts << "I was watching pet with id #{my_pet}. What was her name again?"


# Working with a rate limited API
# requests per minute (rpm) 

rpm     = 3 
seconds = (60 / rpm).to_i + 5 # 5 is a fudge factor

prompts.each_with_index do |prompt, inx|
  puts 

  if inx > 0
    bar = TTY::ProgressBar.new("waiting to start next request [:bar]", total: seconds)
    seconds.times do
      sleep(1)
      bar.advance  # by default increases by 1
    end
  end

  puts
  puts "="*prompt.length
  puts prompt 
  puts

  result = sbox.run prompt

  puts
  puts "Result Class: #{result.class}"
  puts "Result: #{result}"
end
