#!/usr/bin/env ruby
#############################################################
###
##  File: tcp_port_repeater_passive.rb
##  Desc: Repeats all traffic between TCP connections
##
##  LIMITATIONS:
##
##    The tcp_port_repeater has complete access to all ports on
##    the localhost; however, because of the configuration of
##    routers and switchers ports on remote machines may not be
##    visible.  The SOLUTION is to run the tcp_port_repeater
##    on both the local host and the remote host and use a
##    accessible port to communicate one repeater to the other.
##
##  TODO: Add some more robust error checking
##
##  Some thoughts on functionality extension:
##
##    * Use the LocalIP:LocalPort as a control port to
##      control the repeater through commands enter
##      via a telnet connection.  This would allow
##      the port_repeater to be deamonized.
##    * If a repeated port closes, attempt to re-establish
##      the connection.
#

require 'rubygems'
require 'eventmachine'
require 'string_mods'
require 'pp'

############################################
## Globals

$connection_list  = []


#################################################
## Process the command line

if ARGV[0] == '-d'
  $debug = true
  ARGV.shift
else
  $debug = false
end

if ARGV[0].include? ':'
  local_IP_and_port  = ARGV[0].split(':')
  local_IP           = local_IP_and_port[0]
  local_port         = local_IP_and_port[1].to_i
else
  local_IP   = "10.0.52.147"  ## IP_ANY
  local_port = ARGV[0].to_i
end



puts "EM.library_type: #{EM.library_type}"

module MyKeyboardHandler
  include EM::Protocols::LineText2
  def receive_line data
    if $connection_list.length > 0
      puts "sending: #{data}"
      $connection_list[0].send_data data
      puts "sent"
    end
  end
end










###################################################
## PortRepeater accepts traffic from multiple ports
## and repeats it out to every port connected.

class PortRepeater < EventMachine::Connection

  attr_accessor :my_connection_index, :my_address
  
  def initialize *args
    super # will call post_init
    puts "... initialize"
    # whatever else you want to do here
  end ## end of def initialize *args
  
  def post_init
    $connection_list << self
    @my_connection_index = $connection_list.length
    puts "Connection Initialized #{@my_connection_index})  #{@my_address} - #{@signature}"
    #
    # TODO: get access to the HostIP and HostPort associated with this connection
    #       if it is the local control connection, do the following
    #         * do not repeat other connection traffic to this connection
    #         * consider any input a command to be processed
  end ## end of def post_init
  
  def connection_completed
    puts "The connection for #{@my_address} has been successfully completed."
    send_data "Hello from #{ENV['HOSTNAME']}"
  end ## end of def connection_completed
  
  def receive_data data

    from_where = get_peername[2,6].unpack "nC4"
    puts "receive_data:  -=>[#{data}]<=-  from_where: #{from_where.inspect}"
 
  end ## end of def receive_data data
  
  def unbind
     puts "Connection terminated #{@my_connection_index})  #{@my_address} - #{@signature}"
     
     pp self.inspect ## calling the errpr? method crashes: if error?
     
     # TODO: Remove connection from $connection_list
  end ## end of def unbind
  
end ## end of class IseProtocolHandler < EventMachine::Connection

puts "Starting..."
EM.run {
  EM.connect local_IP, local_port,  PortRepeater do |c|  ## Setup the local control port
    c.my_address = "#{local_IP}:#{local_port}"
  end

  EM.open_keyboard(MyKeyboardHandler)
}
 
 puts "Done."

