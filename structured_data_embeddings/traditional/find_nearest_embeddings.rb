#!/usr/bin/env ruby

require 'optparse'

require_relative 'lib/database_connection'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: find_nearest_embeddings.rb [options]"

  opts.on("-f", "--file FILE", "Path to the file to compare") do |f|
    options[:file] = f
  end

  opts.on("-n", "--number NUMBER", Integer, "Number of nearest embeddings to return (default: 3)") do |n|
    options[:number] = n
  end
end.parse!

if options[:file].nil?
  puts "Error: You must provide a file path using the -f or --file option."
  exit 1
end

file_path         = options[:file]
number_of_results = options[:number] || 3

begin
  nearest_embeddings = Embedding.find_nearest_from_file(file_path, number_of_results)

  puts "Nearest #{number_of_results} embeddings for file: #{file_path}"
  puts "----------------------------------------------------"
  
  puts File.read(file_path)

  nearest_embeddings.each_with_index do |result, index|
    puts "-"*64
    puts "#{index + 1}. Record ID: #{result.id}  Distance: #{result.neighbor_distance.round(4)}"
    puts "   Content: #{result.content.to_s.truncate(100)}"
    puts "   Data: #{result.data.to_s.truncate(100)}"
    puts
  end
rescue => e
  puts "An error occurred: #{e.message}"
  exit 1
end
