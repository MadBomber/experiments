#!/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'pp'

udp_address = ARGV[0].split(':')
udp_ip      = udp_address[0]
udp_port    = udp_address[1].to_i

module CustomServer
   def receive_data data
      sender_port_ip_array = get_peername[2,6].unpack "nC4"
      sender_ip            = sender_port_ip_array[1..4].join('.')
      sender_port          = sender_port_ip_array[0]
      sender_addr          = "#{sender_ip}:#{sender_port}"
      puts "From #{sender_addr} received: #{data}"
   end
end

EventMachine::run {
   EventMachine::open_datagram_socket udp_ip, udp_port, CustomServer
}
