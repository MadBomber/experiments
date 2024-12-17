#!/usr/bin/env ruby
require 'json'
require 'net/http'
require 'uri'

class ClaudeCLI
  CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages'
  
  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
    unless @api_key
      STDERR.puts "Error: Please set ANTHROPIC_API_KEY environment variable"
      exit 1
    end
  end

  def send_message(prompt)
    uri = URI.parse(CLAUDE_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['x-api-key'] = @api_key
    request['anthropic-version'] = '2023-06-01'

    request.body = {
      model: 'claude-3-opus-20240229',
      max_tokens: 4096,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ]
    }.to_json

    response = http.request(request)
    
    if response.code == '200'
      parsed_response = JSON.parse(response.body)
      puts parsed_response['content'][0]['text']
    else
      STDERR.puts "Error: #{response.code} - #{response.body}"
      exit 1
    end
  rescue => e
    STDERR.puts "Error: #{e.message}"
    exit 1
  end
end

# Read from STDIN
prompt = STDIN.read.strip
if prompt.empty?
  STDERR.puts "Error: No input provided"
  exit 1
end

# Create client and send message
client = ClaudeCLI.new
client.send_message(prompt)
