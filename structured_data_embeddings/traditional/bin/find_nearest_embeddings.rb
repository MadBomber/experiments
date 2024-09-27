#!/usr/bin/env ruby

require_relative '../lib/database_connection'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: find_nearest_embeddings.rb [options]"

  opts.on("-f", "--file FILE", "Path to the file to compare") do |f|
    options[:file] = f
  end

  opts.on("-n", "--number NUMBER", Integer, "Number of nearest embeddings to return (default: 5)") do |n|
    options[:number] = n
  end
end.parse!

if options[:file].nil?
  puts "Error: You must provide a file path using the -f or --file option."
  exit 1
end

file_path = options[:file]
number_of_results = options[:number] || 5

begin
  nearest_embeddings = Embedding.find_nearest_from_file(file_path)
  
  puts "Nearest #{number_of_results} embeddings for file: #{file_path}"
  puts "----------------------------------------------------"
  
  nearest_embeddings.take(number_of_results).each_with_index do |result, index|
    embedding = result[:embedding]
    distance = result[:distance]
    
    puts "#{index + 1}. Distance: #{distance.round(4)}"
    puts "   Content: #{embedding.content.truncate(100)}"
    puts "   Data: #{embedding.data.truncate(100)}"
    puts
  end
rescue => e
  puts "An error occurred: #{e.message}"
  exit 1
end
