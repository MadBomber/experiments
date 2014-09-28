#!/bin/env ruby
require 'rubygems'
require 'eventmachine'

EM.run {
  pong = EM.spawn {|x, ping|
    puts "Pong received #{x}"
    ping.notify( x-1 )
  }

  ping = EM.spawn {|x|
    if x > 0
      puts "Pinging #{x}"
      pong.notify x, self
    else
      EM.stop
    end
  }

  ping.notify 3
}

