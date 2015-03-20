#!/usr/bin/env ruby
# server

require 'drb'

class DistCalc
  def find_distance(p1, p2)
    Math.sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2)
  end
end

DRb.start_service nil, DistCalc.new
puts DRb.uri

DRb.thread.join
