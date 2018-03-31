#!/usr/bin/env ruby
#######################################################
###
##  File: time_this.rb
##  Desc: Correct way to measure time to avoid NTP interference
##  See:  https://blog.dnsimple.com/2018/03/elapsed-time-with-ruby-the-right-way/
#

def time_this &block
  _time_this_starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  block.call
  Process.clock_gettime(Process::CLOCK_MONOTONIC) - _time_this_starting
end

5.times do
  puts time_this { sleep 1 }
end
