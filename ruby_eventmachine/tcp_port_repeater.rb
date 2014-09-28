#!/bin/env ruby
#############################################################
###
##  File: tcp_port_repeater.rb
##  Desc: Repeats all traffic between two TCP ports
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
require 'pp'

#################################################
## Process the command line

if 2 > ARGV.length
  puts <<EOF

Repeat all TCP traffic between ports.

Usage: tcp_port_repeater [-d] [LocalIP:]LocalPort RemoteIP:RemotePort [RemoteIP:RemotePort]*

  Where:
  
    -d            Turns on debugging
  
    LocalIP       Defaults to 0.0.0.0 (IP_ANY)
    LocalPort     A port on the localhost
    RemoteIP      The IP address of a remote host (could also be 127.0.0.1)
    RemotePort    A port on the RemoteIP host computer
    
    The RemoteIP:RemotePort parameter can be repeated zero or more times.

Limitation: RemoteIP:RemotePort must be visible to this machine.  If it is not,
            then run tcp_port_repeater on the remote machine and choose a port
            that is visible between the two.  If you can not ping the
            remote IP, then there is nothing you can do to forward
            data to there.
EOF

  exit -1
end

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
  local_IP   = "0.0.0.0"  ## IP_ANY
  local_port = ARGV[0].to_i
end

$remotes = []

for xxx in 1..ARGV.length - 1
  # SMELL: What if the user entered the same IP:Port more than once?
  $remotes << ARGV[xxx].split(':')
end

pp $remotes


############################################
## Globals

$connection_list  = []


###################################################
## PortRepeater accepts traffic from multiple ports
## and repeats it out to every port connected.

class PortRepeater < EventMachine::Connection

  attr_accessor :my_connection_index, :my_address
  
  def initialize *args
    super # will call post_init
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
  end ## end of def connection_completed
  
  def receive_data data
#    unless I am the local control port
      if $debug
        from_where = get_peername[2,6].unpack "nC4"
        puts "#{from_where.inspect} #{data.to_hex}"
      end
      $connection_list.each do |c|
        c.send_data data  unless c.signature == @signature  ## do not echo back data to its sender
      end
#    else
#      data contains a command from the lecal control port
#      process the command
#    end
  end ## end of def receive_data data
  
  def unbind
     puts "Connection terminated #{@my_connection_index})  #{@my_address} - #{@signature}"
     
     pp self.inspect if error?
     
     # TODO: Remove connection from $connection_list
  end ## end of def unbind
  
end ## end of class IseProtocolHandler < EventMachine::Connection


EM.run {
  EM.start_server local_IP, local_port,  PortRepeater ## Setup the local control port
  $remotes.each do |r|
    EM.connect      r[0], r[1].to_i, PortRepeater do |c|     ## connect to all of the remote ports
      c.my_address = "#{r[0]}:#{r[1]}"
    end
  end
}
 
 puts "Done."

