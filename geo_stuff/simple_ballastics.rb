#!/usr/bin/env ruby
############################################################
###
##	File:	simple_ballastics.rb
##	Desc:	A simplified 2d ballastics example
#

GRAVITY				    = 9.8	  # meters per second ^2

launch_angle_deg  = 45.0	  # in degrees
launch_angle_rad  = launch_angle_deg * Math::PI / 180

initial_velocity	= 100.0 	# meters per second

# y = Ax - Bx^2
# where the coefficients A and B are
# A = tanq
# B = ½ g/(v0 cosq)^2

a = Math::tan(launch_angle_rad)
b = 0.5 * GRAVITY / (initial_velocity * Math::cos(launch_angle_rad) ) **2

y = 0
x = 0
max_y = 0
while ( y >= 0) do
  y = a * x - b * x **2
  max_y = y if y > max_y
  x += 1
  puts x, y
end

puts "Range:  #{x}"
puts "Height: #{max_y}"
