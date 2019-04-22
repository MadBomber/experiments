#!/usr/bin/env ruby
##########################################
## extract_words.rb

require 'json'
require 'awesome_print'
require 'debug_me'
include DebugMe

# over 370K valid English words ... might be too big!
W = JSON.parse File.open('./words_dictionary.json').read

# get rid of some of those words ...

aeiou = %w[ a e i o u ]

('a'..'z').each {|x| W[x] = nil}
%w[ a i ].each {|x| W[x] = 1}

W.keys.select {|x| 2==x.size}.each do |x|
  W[x] = nil unless (aeiou.include?(x[0]) || aeiou.include?(x[1]))
end

W.keys.select {|x| 3==x.size}.each do |x|
  W[x] = nil unless (aeiou.include?(x[0]) || aeiou.include?(x[1]) || aeiou.include?(x[2]))
end


##################################
## Main Stuff

def collect_words(a_string, char_indexes, direction=:forward)
  words = Array.new
  char_indexes.each do |edge_index|
    candidate = :forward == direction ? a_string[0..edge_index] : a_string[edge_index..a_string.size-1]
    words << candidate if W[candidate]
  end

  return words
end


def determine_char_indexes(a_string, direction=:forward)
  if :forward == direction
    start         = 1
    stop          = a_string.size
    char_indexes  = (start..stop).to_a
  else
    start         = a_string.size - 1
    stop          = 0
    char_indexes  = (stop..start).to_a.reverse
  end

  return char_indexes
end


def find_valid_words(a_string, direction=:forward)
  return [] if a_string.empty?

  char_indexes  = determine_char_indexes(a_string, direction)
  words         = collect_words(a_string, char_indexes, direction)
  return words
end


def backtrace(tree, a_string)
  last_node = tree.last
  node_size = last_node.size
  if node_size > 1
    curr = last_node[node_size-1]
    prev = last_node[node_size-2]

    restore_string = curr[prev.size..]
    a_string = restore_string + a_string
    tree[tree.size-1] = last_node[0..node_size-2]
  end

  return tree, a_string
end


def extract_words_1(a_string, result=[], backup=0)
  return result if a_string.empty?

  words = find_valid_words(a_string, :forward)

  unless words.empty?
    result   << words
    a_string  = a_string.delete_prefix(words.last)
    result    = extract_words_1(a_string, result)
  else
    if 0 == backup # do only one backtrace
      result, a_string = backtrace(result, a_string)
      result = extract_words_1(a_string, result, backup+1)
    else
      unless a_string.empty?
        # puts "debug: found no words in: #{a_string}"
        result << [a_string]
      end
    end
  end

  return result
end

=begin
  girlsdressupdollsinprettydresses
  girlsdressupdollsinpretty dresses
  girlsdressupdollsin pretty dresses
  girlsdressupdoll sin pretty dresses
  girlsdressupdoll sin pretty dresses
  girlsdressup doll sin pretty dresses
  girlsdres sup doll sin pretty dresses
  girlsd res sup doll sin pretty dresses

=end

def backtrace_2(tree, a_string)
  last_node = tree.last
  node_size = last_node.size
  if node_size > 1
    curr = last_node[node_size-1]
    prev = last_node[node_size-2]


    restore_string = curr[prev.size..]
    a_string = restore_string + a_string

debug_me{[ :tree, :curr, :prev, :restore_string, :a_string ]}

    tree[tree.size-1] = last_node[0..node_size-2]
  end

  debug_me {[ :tree, :a_string ]}

  return tree, a_string
end


def extract_words_2(a_string, result=[], backup=0)
  return result if a_string.empty?

  words = find_valid_words(a_string, :backward)

  unless words.empty?
    result   << words
    a_string  = a_string.delete_suffix(words.last)

    result    = extract_words_2(a_string, result)
  else
    if 0 == backup # do only one backtrace
      result, a_string = backtrace_2(result, a_string)
      debug_me{[ :result, :a_string ]}
      result = extract_words_2(a_string, result, backup+1)
      debug_me{[ :result ]}
    else
      unless a_string.empty?
        # puts "debug: found no words in: #{a_string}"
        result << [a_string]
      end
    end
  end

  return result
end


def extract_words(a_string)
  result = Array.new
  result_tree = extract_words_1(a_string)
  result << result_tree.map {|node| node.last}.join(' ')
  result_tree = extract_words_2(a_string)
  result << result_tree.map {|node| node.last}.reverse.join(' ')

  return result
end


def test
  [
    'tellthetruthmister',
    'boysplaywithtrucks',
    'girlsdressupdollsinprettydresses'
  ].each do |test_string|
    puts "\nTesting:    #{test_string}"
    results = extract_words(test_string)

    puts "RESULT:"
    puts "  Forward:  #{results.first}"
    puts "  Backward: #{results.last}"
  end
end

puts "\n\n"
test
puts "\n\n"

