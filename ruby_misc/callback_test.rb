#!/usr/bin/env ruby
#########################################
###
##  File:  callback_test.rb
##  Desc:  testing ways of accessing methods for use as callback functions
#

require 'pp'

###########################
## Start Simple

def one
  'a one'
end

def two
  'and a two'
end

a_hash = Hash.new

a_hash['1'] = method(:one)
a_hash['2'] = method(:two)

a_hash.each do |k, v|
  puts "key: #{k}  Value: #{v.call}"
end



###################################
## Get More Complex

module Peerrb

  module Missile
    puts "inside Missile"
    def self.three data       ## <=- key to success is the 'self.' making this a class method
      "and a three => #{data}"
    end
  end

end


def one data
  "a one => #{data}"
end

def two data
  "and a two => #{data}"
end



$a_hash = Hash.new

$a_hash['1'] = method(:one)
$a_hash['2'] = method(:two)

$a_hash.each do |k, v|
  puts "key: #{k}  Value: #{v.call(k)}"
end


def subscribe digit, callback
  $a_hash[digit] = callback
end



subscribe 3, "Peerrb::Missile.three"

pp $a_hash

$a_hash.each do |k, v|
  puts "key: #{k}  Value: #{v.call(k)}" if 'Method' == v.class.to_s
  v += "(k)"  if 'String' == v.class.to_s
  puts "key: #{k}  Value: #{eval(v)}" if 'String' == v.class.to_s
end



