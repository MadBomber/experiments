#!/usr/bin/env ruby
# experiments/ollama/ollama_test.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'net/http'
require 'uri'
require 'json'


uri = URI('http://localhost:11434/api/chat')


request = Net::HTTP::Post.new(uri)
request.content_type = 'application/json'
request.body = JSON.dump({
 model: 'ruby',
 messages: [
   {
     role: 'user',
     content: 'write a ruby program to covert a PDF into text?',
   }
 ],
 stream: false
})


response = Net::HTTP.start(uri.hostname, uri.port) do |http|
 http.read_timeout = 120
 http.request(request)
end


response = JSON.parse(response.body)

ap response

puts "="*64
puts "== content"
puts 

puts response.dig('message', 'content')
