#!/usr/bin/env ruby
# client

require 'drb'

Point = Struct.new 'Point', :x, :y

class Point
  include DRbUndumped

  def to_s
    "(#{x}, #{y})"
  end
end

DRb.start_service
dist_calc = DRbObject.new nil, ARGV.shift

p1 = Point.new 0, 0
p2 = Point.new 1, 0

puts "The distance between #{p1} and #{p2} is #{dist_calc.find_distance p1, p2}"
