#!/usr/bin/env ruby

require 'awesome_print'
require 'debug_me'
include DebugMe

google_earth_icon_mapping = {
  unclassified:   31,
  confidential:   13,
  secret:         29,
  topsecret:      30
}

icon_mapping = google_earth_icon_mapping.to_a

fixed_point = [37.2350000, -115.8111111]  # Area 51
delta       = [15, 15]

max = 40

puts "Latitude\tLongitude\tName\tDescription\tIcon"

(1..max).each do |x|
  offset  = []
  dir     = rand(2) == 0 ? -1.0 : 1.0
  offset << dir * rand(delta.first).to_f  / 10.0
  dir     = rand(2) == 0 ? -1.0 : 1.0
  offset << dir * rand(delta.last).to_f / 10.0
  point   = fixed_point.each_with_index.map {|v, x| v + offset[x]}
  name    = "img_#{sprintf('%04d', x*10)}.jpg"
  level   = rand(icon_mapping.size)
  desc    = icon_mapping[level].first.to_s
  icon    = icon_mapping[level].last
  print point.first.to_s + "\t"
  print point.last.to_s + "\t"
  print name + "\t"
  print desc + "\t"
  puts icon
end







