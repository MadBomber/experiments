#!/usr/bin/env ruby

require 'optparse'

require_relative 'lib/database_connection'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: find_nearest_embeddings.rb [options]"

  opts.on("-n", "--number NUMBER", Integer, "Number of nearest embeddings to return (default: 3)") do |n|
    options[:number] = n
  end
end.parse!

number_of_results = options[:number] || 3

print "What kind of a house are you interested in? "
user_prompt = gets.chomp

begin
  nearest_embeddings = Embedding.find_nearest_from_text(user_prompt, number_of_results)

  puts "\nNearest #{number_of_results} embeddings for prompt: #{user_prompt}"
  puts "----------------------------------------------------"

  nearest_embeddings.each_with_index do |result, index|
    puts "-"*64
    puts "#{index + 1}. Record ID: #{result.id}  Distance: #{result.neighbor_distance.round(4)}"
    puts "   Content: #{result.content.to_s}" # .truncate(100)
    puts "   Data: #{result.data.to_s}"       # .truncate(100)
    puts
  end
rescue => e
  puts "An error occurred: #{e.message}"
  exit 1
end
