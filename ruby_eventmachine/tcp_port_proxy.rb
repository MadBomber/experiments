#!/bin/env ruby
#############################################################
###
##  File: tcp_port_proxy.rb
##  Desc: Sits inbetween two TCP ports
##
#

require 'rubygems'
require 'eventmachine'
require 'string_mods'
require 'pp'

#################################################
## Process the command line

if 2 > ARGV.length
  puts "command parameters are not right"

=begin
  Monitor all TCP traffic between two ports.

  Usage: tcp_port_proxy [-d] LocalIP:LocalPort RemoteIP:RemotePort

  Where:

  -d            Turns on debugging/logging

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
=end

  exit -1
end

if ARGV[0] == '-d'
  $debug = true
  ARGV.shift
else
  $debug = false
end



local_IP_and_port  = ARGV[0].split(':')
local_IP           = local_IP_and_port[0]
local_port         = local_IP_and_port[1].to_i


remote_IP_and_port  = ARGV[1].split(':')
remote_IP           = remote_IP_and_port[0]
remote_port         = remote_IP_and_port[1].to_i





############################################
## Globals

$connection_list  = []


###################################################
## PortRepeater accepts traffic from multiple ports
## and repeats it out to every port connected.

class PortRepeater < EventMachine::Connection

  @@msg_queue = []


  attr_accessor :my_connection_index, :my_address

  def initialize *args
    super # will call post_init
    # whatever else you want to do here
  end ## end of def initialize *args

  def post_init
    $connection_list << self
    @my_connection_index = $connection_list.length
    puts "Connection Initialized #{@my_connection_index})  #{@my_address} - #{@signature}"


    if @@msg_queue.length > 0
      @@msg_queue.each do |mq|
        puts "sending from queue: #{mq.to_hex}"
        send_data mq
        puts "sent"
      end
      @@msg_queue = []
    end



  end ## end of def post_init

  def connection_completed
    puts "The connection for #{@my_address} has been successfully completed."

  end ## end of def connection_completed

  def receive_data data
    #    unless I am the local control port
    if $debug
      from_where = get_peername[2,6].unpack "nC4"
      puts "LOGLOGLOG: Received from: #{from_where.inspect} #{data.to_hex}"
    end

    if 1 == $connection_list.length
      @@msg_queue << data
      puts "data was queued: #{data.to_hex}"
    else
#puts "DEBUG: #{__LINE__}"
      $connection_list.each do |c|
#puts "DEBUG: #{__LINE__}"
        unless c.signature == @signature  ## do not echo back data to its sender
#puts "DEBUG: #{__LINE__}"
          if @@msg_queue.length > 0
#puts "DEBUG: #{__LINE__}"
            @@msg_queue.each do |mq|
#puts "DEBUG: #{__LINE__}"
              puts "forwarding from queue: #{mq.to_hex}"
              c.send_data mq
              puts "forwarded"
            end
#puts "DEBUG: #{__LINE__}"
            @@msg_queue = []
          end
#puts "DEBUG: #{__LINE__}"
          puts "sending: #{data.to_hex}"
          c.send_data data
          puts "sent"
        else
#puts "DEBUG: #{__LINE__}"
        end
      end
    end

  end ## end of def receive_data data

  def unbind
    puts "Connection terminated #{@my_connection_index})  #{@my_address} - #{@signature}"

    pp self.inspect if error?

    # TODO: Remove connection from $connection_list
  end ## end of def unbind

end ## end of class IseProtocolHandler < EventMachine::Connection


EM.run {
  EM.connect local_IP,  local_port,   PortRepeater do |c|     ## connect to all of the remote ports
    c.my_address = "#{local_IP}:#{local_port}"
  end
  
  EM.start_server remote_IP, remote_port,  PortRepeater do |c|     ## connect to all of the remote ports
    c.my_address = "#{remote_IP}:#{remote_port}"
  end
  
  EM.add_periodic_timer(10) do
    puts "========= proxy alive at: #{Time.now}"
    $stdout.flush
  end
}

puts "Done."

