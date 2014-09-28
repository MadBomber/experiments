#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'string_mods'

module EchoServer
  def receive_data data
    puts data       #.to_hex
    $stdout.flush
    close_connection if data =~ /quit/i
  end
end

EventMachine::run {
  EventMachine::start_server '0.0.0.0', 5557, EchoServer
}

