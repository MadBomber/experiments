#!/usr/bin/env ruby
# experiments/hash_and_sort_by/etl.rb
# and ETL exercise
#
# Requirements:
#   from the world of Harry Potter ....
#   For each house, show the dude with the most friends.
#   When a house has dudes with the same maximum friend cout,
#   select the dude whose name is first alphabetically.

require "json"

# Extract
data = JSON.parse(File.read('etl.json'))

# Transform

# Every time you allocate a new entry in this
# Hash object, make its value an empty Array object
temp = Hash.new { |h,k| h[k] = [] }

data.each do |entry|
  house   = entry['house']
  name    = entry['name']
  friends = entry['friends'].size
  temp[house] << { name => friends }
end

# Remember "temp" is a Hash with a String Key and a Value that
# is an Array of Hashes.

# Transform Again and Load
#             (String) Key    Value (Array or Hashes)
output  = temp.map do |house, dudes_with_friends|
  dude  = dudes_with_friends
            .sort_by { |h|  # sorting Hash objects **ascending**
              [             # on two levels: number of friends, dude's name
              # v=-< Don't miss the minus sign 
              # v    (looking for the most friends)
              # v    and the sort is ascending 
                -h.values.first,  # an Array with one element
                h.keys.first      # ditto
              ]
            }
            .first  # Dude's entry with most friends count
            .keys   # Array of Dude's names sorted alphabetically
            .first  # this is the one that meets the requirement
            
  { house => dude } # we're mapping, so this entry replaces the original
end

puts "Human answer ..."
puts output


##################################################
# Robot wrote this code ...

class String    # Human had to add this
  def present?
    !self&.empty?
  end
end

# Parse the JSON data
characters = JSON.parse(File.read('etl.json'))

# Initialize a hash to hold the friends count for each house
house_friends = Hash.new { |hash, key| hash[key] = [] }

# Count friends for each character by their house
characters.each do |character|
  if character['house'].present?
    friends_count = character['friends'].size
    house_friends[character['house']] << { name: character['name'], friends_count: friends_count }
  end
end

# Find the character with the most friends in each house
result = house_friends.transform_values do |characters_in_house|
  characters_in_house.max_by do |char|
    [char[:friends_count], -char[:name].downcase]
  end[:name]
end

puts "\nRobot answer ..."

# Output the result
puts "Character with the most friends in each house:"
result.each do |house, character_name|
  puts "#{house}: #{character_name}"
end



