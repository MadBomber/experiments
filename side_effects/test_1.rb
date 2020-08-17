#!/usr/bin/env ruby

one = 1

puts one

def side_effect(one)
  puts one
  one = 2   # This should be scoped locally to the method and no side-effect
end

side_effect(one)

puts one

unless 1 == one
  puts "YES side effect"
  puts "object_id of 1 is   #{1.object_id}"
  puts "object_id of one is #{one.object_id}"
else
  puts "NO side_effect"
end

########################################

two = 2

puts two

def side_effect2(two)
  puts two
  two = 'two'   # This should be scoped locally to the method and no side-effect
end

side_effect2(two)

puts two

unless 2 == two
  puts "YES side effect"
  puts "object_id of 2 is   #{2.object_id}"
  puts "object_id of two is #{two.object_id}"
else
  puts "NO side_effect"
end

