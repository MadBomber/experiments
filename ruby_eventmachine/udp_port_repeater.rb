#!/bin/env ruby
#############################################################
###
##  File: udp_port_repeater.rb
##  Desc: Establishes a UDP repeater service at a specific port
##        on the local host.
##
##  Testing on Unix:
##
##    You can use the "nc -l -k -u ip port" command to send and receive udp packets
#
require 'socket'    ## low-level socket communications
require 'pathname'  ## cross-platform pathnames
require 'pp'        ## pretty-printer

# TODO: Retrieve these constants from the command line

TIMEOUT_SECONDS   = 0       ## time to wait at the select before echoing a packet
                            ## A value of 1 will wait 1 second between packet transmissions
                            ##          0.5 will wait a half second

if RUBY_PLATFORM.include? "mswin32"     ## I hate windoze!
    TIMEOUT_SECONDS = 0.001 if TIMEOUT_SECONDS < 0.001
end

BUFFER_SIZE_BYTES = 1024    ## maximum size of a received data packet
                            ## data that exceeds this size will be truncated

puts TIMEOUT_SECONDS
puts BUFFER_SIZE_BYTES

###################################
# Proces the command line arguments

if 2 > ARGV.length  ## TODO: add robus commandline parsing

  puts <<EOF

UDP port repeater.

Usage: #{Pathname.new($0).basename} [-d] [LocalIP:]LocalPort RemoteIP:RemotePort [RemoteIP:RemotePort]*

  Where:

    -d            Turns on debugging output

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
  $debug = true
  ARGV.shift
else
  $debug = false
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
    punch.send('', 0, r[0], r[1])
    punch.close
end


######################################
# Bind for receiving on local ip, port

udp_in = UDPSocket.new
udp_in.bind(local_ip, local_port)
puts "Local binding -=> #{local_ip} #{local_port}"


###############################################
# Listen for a while, if nothing send something

loop do
  # Receive data or time out after 5 seconds
  if IO.select([udp_in], nil, nil, TIMEOUT_SECONDS)
        data = udp_in.recvfrom(BUFFER_SIZE_BYTES)
        # sender_type = data[1][0]
        sender_port = data[1][1]
        # sender_name = data[1][2]
        sender_ip   = data[1][3]
        sender_addr = "#{sender_ip}:#{sender_port}"

        pp data.inspect if $debug

        $remotes.each do |r|
          unless r[2] == sender_addr          ## do not echo data back to sender
            # $stdout.print "*" unless $debug
            # $stdout.flush unless $debug
            puts "Relaying #{data[0]} to #{r[2]}" if $debug
            udp_in.send(data[0], 0, r[0], r[1])
          end
        end
  else  ## SMELL: Is this else clause necessary outside of testing?
        # $stdout.print "." unless $debug
        # $stdout.flush unless $debug
        # message_out = Time.now.to_s + "\n"
        message_out = ''
        x = 0 if $debug
        $remotes.each do |r|
          x += 1 if $debug
          $stdout.print "#{x}" if $debug
          $stdout.flush if $debug
          # puts "#{r[0]}:#{r[1]}" if $debug
          udp_in.send(message_out, 0, r[0], r[1])
        end
  end
end
