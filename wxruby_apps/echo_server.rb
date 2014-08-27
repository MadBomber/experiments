#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'

module EchoServer
  def receive_data data
    send_data ">>>you sent: #{data}"
    close_connection if data =~ /quit/i
  end
end

EventMachine::run {
  EventMachine::start_server "localhost", 8081, EchoServer
}

