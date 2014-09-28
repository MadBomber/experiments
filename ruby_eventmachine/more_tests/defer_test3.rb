#!/usr/bin/env ruby

require 'eventmachine'
require 'thread'

EM.run do

 EM.add_timer(2) do
   puts "Main #{Thread.current}"
   EM.stop_event_loop
 end

 EM.defer(proc do
   puts "Defer #{Thread.current}"
 end)

end

