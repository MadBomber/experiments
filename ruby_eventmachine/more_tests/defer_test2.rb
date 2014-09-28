#!/usr/bin/env ruby


require 'eventmachine'

EM.run do

 df = EM::DefaultDeferrable.new
 df.callback do |x|
   puts "got #{x}"
 end


 df.callback do |x|
   EM.stop
 end

 EM.add_timer(1) do
   df.set_deferred_status :succeeded, "monkeys"
 end

end

