#!/usr/bin/env ruby

require 'optparse'

require_relative 'lib/database_connection'

options = {}
OptionParser.new do |opts|
  opts.on("-n", "--number NUMBER", Integer, "Number of nearest embeddings to return (default: 3)") do |n|
    options[:number] = n
  end
  opts.on('--from TYPE', ['text', 'json'], "Source type (text or json)") do |v|
    options[:from] = v
  end
end.parse!

number_of_results = options[:number] || 6

print "What kind of a house are you interested in? "
user_prompt = gets.chomp

system_user_prompt = <<~PROMPT
  You are a real estage agent with a client.  
  Your client has asked you to tell them abount 
  houses which meets the client's wants.

  Specifically the client has told you 
  "#{user_prompt}"

  Tell the client about the following houses 
  that are in your inventory and how they meet 
  the client's requirements.

  Your inventory includes the following houses:

PROMPT

inventory = ""

nearest_embeddings = Embedding.find_nearest_from_text(user_prompt, number_of_results)

nearest_embeddings.each_with_index do |result, index|
  inventory << "\n\n"
  inventory << "#{index + 1}. Record ID: #{result.id}\n"  #  Distance: #{result.neighbor_distance.round(4)}"
  inventory << ('json' == options[:from] ? result.data : result.content)
end

final_prompt = system_user_prompt + inventory

prompts_dir = Pathname.new ENV.fetch('AIA_PROMPTS_DIR')

final_prompt_path = prompts_dir + 'house_hunting.txt'
final_prompt_path.write final_prompt

response = `aia house_hunting --no-out_file`

puts
puts response
puts
puts <<~TEXT
  To keep chating about house hunting enter this
  command:
    aia house_hunting --chat --no-out_file

TEXT

