#!/usr/bin/env ruby
#############################################################
###
##  File: udp_port_repeater_em.rb
##  Desc: Repeats all traffic between two UDP ports
##
##  LIMITATIONS:
##
##    The udp_port_repeater has complete access to all ports on
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
require 'string_mods'
require 'pathname'
require 'eventmachine'
require 'socket'
require 'pp'

#################################################
## Process the command line

if 2 > ARGV.length
  puts <<EOF

UDP port repeater.

Usage: #{Pathname.new($0).basename} [-d] [-p] [-v] [LocalIP:]LocalPort RemoteIP:RemotePort [RemoteIP:RemotePort]*

  Where:

    -d            Turns on debugging output and verbose output

    -p            Sends a new-line character to all remote ports
                  2 seconds after starting the repeater
                  "prime-the-port"

    -v            verbose prints a period every second and a $ every
                  5 seconds to the standard-error stream on the console

    LocalIP       Defaults to 0.0.0.0 (IP_ANY)
    LocalPort     A port on the localhost
    RemoteIP      The IP address of a remote host (could also be 127.0.0.1)
    RemotePort    A port on the RemoteIP host computer

    RemoteIP:RemotePort must can be repeated as necessary

EOF

  exit -1
end


# SMELL: requires commandline options to be in specific order

if ARGV[0] == '-d'
  $debug   = true
  $verbose = true
  ARGV.shift
else
  $debug   = false
  $verbose = false
end

if ARGV[0] == '-p'
  $prime_the_port = true
  ARGV.shift
else
  $prime_the_port = false
end

if ARGV[0] == '-v'
  $verbose = true
  ARGV.shift
else
  $verbose = false
end


if ARGV[0].include? ':'
  local_ip_and_port  = ARGV[0].split(':')
  local_ip           = local_ip_and_port[0]
  local_port         = local_ip_and_port[1].to_i
else
  local_ip   = "0.0.0.0"  ## IP_ANY
  local_port = ARGV[0].to_i
end

$remotes = []

for xxx in 1..ARGV.length - 1
  # SMELL: What if the user entered the same IP:Port more than once?
  #        Then the packets would be sent twice; feature or bug?
  $remotes << ARGV[xxx].split(':')
  $remotes[xxx-1][1] = $remotes[xxx-1][1].to_i  ## converts string to integer for the port number
  $remotes[xxx-1] << ARGV[xxx]
end



if $debug
  puts "Command line parameters:"
  puts "Local  -=> #{local_ip} #{local_port}"
  pp $remotes.inspect
end


# =begin
##########################
# Punches hole in firewall

$remotes.each do |r|
    puts "Knocking on #{r[0]}:#{r[1]}" if $debug
    punch = UDPSocket.new
    begin
      punch.bind('', r[1])
    rescue
      puts
      puts "ERROR: #{$!}"
      puts
      puts "If the IP #{r[0]} is associated with this machine, try starting this"
      puts "repeater first before attempting to startup the process on port #{r[1]}"
      puts
      exit -1
    end
    punch.send("boo! did the socket scare you?\n", 0, r[0], r[1])
    punch.close
end

# =end


############################################
## Globals

$connection_list  = []


###################################################
## PortRepeater accepts traffic from multiple ports
## and repeats it out to every port connected.

class UdpPortRepeater < EventMachine::Connection

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
      sender_port_ip_array = get_peername[2,6].unpack "nC4"
      sender_ip            = sender_port_ip_array[1..4].join('.')
      sender_port          = sender_port_ip_array[0]
      sender_addr          = "#{sender_ip}:#{sender_port}"
      puts "From #{sender_addr} received: #{data.to_hex}" if $debug

      $remotes.each { |r|
        unless r[2] == sender_addr          ## do not echo data back to sender
          # $stdout.print "*" unless $debug
          # $stdout.flush unless $debug
          puts "Relaying #{data} to #{r[2]}" if $debug
          send_datagram data, r[0], r[1]
        end
      }



  end ## end of def receive_data data

  def unbind
     puts "Connection terminated #{@my_connection_index})  #{@my_address} - #{@signature}"

     pp self.inspect if error?

     # TODO: Remove connection from $connection_list
  end ## end of def unbind

end ## end of class IseProtocolHandler < EventMachine::Connection


########################
## Event Loop

EM.run {
  if $verbose
    EM::add_periodic_timer( 1 ) { $stderr.write "." } ## code block executes every second
    EM::add_periodic_timer( 5 ) { $stderr.write "$" } ## block executes every 5 seconds
  end

  EM.open_datagram_socket local_ip, local_port,  UdpPortRepeater do |c| ## Setup the local control port
    c.my_address = "#{local_ip}:#{local_port}"
    EM::add_timer( 5 ) { c.send_datagram "wakeup\n", local_ip, local_port } if $prime_the_port ## prime the local port
    EM::add_periodic_timer( 10 ) { c.send_datagram Time.now.to_s+"\n", local_ip, local_port } if $prime_the_port ## prime the local port
  end

  $remotes.each do |r|
    EM.connect r[0], r[1],  UdpPortRepeater do |c| ## Setup the remotes
      c.my_address = r[2]
    end
  end

}

 puts "Done."

