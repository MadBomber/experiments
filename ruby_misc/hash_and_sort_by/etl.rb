#!/usr/bin/env ruby
# experiments/hash_and_sort_by/etl.rb
#
# Requirements:
#   For each house, show the dude with the most friends.
#   When a house has dues with the same maximum friend cout,
#   select the dude whose name is first alphabetically.

require "json"

# Extract
data = JSON.parse(File.read('etl.json'))

# Transform
temp = Hash.new { |h,k| h[k] = [] }

data.each do |entry|
  house   = entry['house']
  name    = entry['name']
  friends = entry['friends'].size
  temp[house] << { name => friends }
end

# Transform Again and Load
output  = temp.map do |house, dudes_with_friends|
  king  = dudes_with_friends.sort_by {|h| [-h.values.first, h.keys.first ]}
            .first.keys.first
            
  { house => king}
end

puts output
