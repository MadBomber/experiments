#!/usr/bin/env ruby
# experiments/openai/using_functions/example.rb

require "net/http"
require "uri"
require "json"
require "openai"
require "optparse"

# Fetch the webpage text
def fetch_webpage_text(url:)
  response = Net::HTTP.get(URI(url))
  response
end

# Summarize webpage content using OpenAI API
def summarize_webpage_content(url:, api_key:)
  client = OpenAI::Client.new(access_token: api_key)
  response = client.chat(
    parameters: {
      model: "gpt-4",  # Ensure this model is available with your API key
      messages: [
        { role: "user", content: "What does the webpage say?" },
        { role: "function", name: "fetch_webpage_text", content: url },
      ],
    },
  )
  
  response.dig("choices", 0, "message", "content")
end

# Main method to handle command-line interface
def main
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.on("-u", "--url URL", "The URL of the webpage to summarize") do |url|
      options[:url] = url
    end
  end.parse!

  # Validate options
  unless options[:url]
    puts "A URL is required."
    puts "Usage: example.rb -u http://example.com"
    exit 1
  end

  # Retrieve API key from environment variable
  api_key = ENV['OPENAI_API_KEY']
  unless api_key
    puts "The environment variable OPENAI_API_KEY is not set."
    exit 1
  end

  # Fetch and summarize webpage content
  begin
    webpage_text = fetch_webpage_text(url: options[:url])
    summary = summarize_webpage_content(url: options[:url], api_key: api_key)

    puts "\nWebpage Summary:\n"
    puts summary
  rescue OpenAI::Error => e
    puts "An error occurred while communicating with the OpenAI API: #{e.message}"
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
  end
end

main
