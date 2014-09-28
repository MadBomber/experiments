#!/bin/env ruby
#############################################################
###
##  File: tcp_test_server.rb
##  Desc: Establishes a TCP server that sends/receives stuff
##
#

require 'rubygems'
require 'eventmachine'
require 'pp'

#################################################
## Process the command line

unless 2 == ARGV.length
  puts <<EOF

UDP server - sends and receives stuff

Usage: udp_test_server LocalIP LocalPort

  Where:
  
    LocalIP       Defaults to 0.0.0.0 (IP_ANY)
    LocalPort     A port on the localhost (a TCP port used to control this repeater)
        
EOF

  exit -1
end




local_IP   = ARGV[0]
local_port = ARGV[1].to_i



###################################################
## PortRepeater accepts traffic from multiple ports
## and repeats it out to every port connected.

class UdpPortRepeater < EventMachine::Connection

  attr_accessor :my_address
  
  def initialize *args
    super # will call post_init
    # whatever else you want to do here
    @my_address = "NotDefinedYet"
  end ## end of def initialize *args
  
  def post_init
     puts "Connection Initialized #{@my_address} - #{@signature}"
    #
    # TODO: get access to the HostIP and HostPort associated with this connection
    #       if it is the local control connection, do the following
    #         * do not repeat other connection traffic to this connection
    #         * consider any input a command to be processed
 #   send_data "post_init for #{@my_address} Started #{Time.now}\n"

    EM::add_periodic_timer( 5+rand(5) ) { $me.send_data "#{$me.my_address} -=> #{Time.now}\n" } ## block executes every 5 to 9 seconds

  end ## end of def post_init
  
  def receive_data data
    puts data
  end ## end of def receive_data data
  
  def unbind
     puts "Connection terminated #{@my_address} - #{@signature}"
     # TODO: Remove connection from $connection_list
  end ## end of def unbind
  
  
  #######################
  ## Non callback methods
  
  def debug_me
    pp self.inspect
  end
  
end ## end of class IseProtocolHandler < EventMachine::Connection

############################
## Initialize the event loop

puts "cntl-c to quit."

EM.run {
  puts "Attempting to start_server for #{local_IP}:#{local_port} ..."
#  EM.open_datagram_socket local_IP, local_port.to_i, UdpPortRepeater do |c|   ## connect to all of the UDP remote ports
  EM.start_server local_IP, local_port.to_i, UdpPortRepeater do |c|   ## connect to all of the UDP remote ports    c.my_address = "#{local_IP}:#{local_port}"
    c.my_address = "#{local_IP}:#{local_port}"
    $me = c
  end
}

############################
## Event loop has terminated

puts "Done."

