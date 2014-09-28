#!/usr/bin/env ruby

require 'eventmachine'

EM.run do

 s = EM.spawn do |val|
   puts "Received #{val}"
 end

 EM.add_timer(1) do
   s.notify "hello"
 end

 EM.add_periodic_timer(1) do
   puts "Periodic"
 end

 EM.add_timer(3) do
   EM.stop
 end

end

