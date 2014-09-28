#!/usr/bin/env ruby
#############################################################
###
##  File:  data_dumper.rb
##  Desc:  Dumps data from a specific IP:PORT
#


$local_IP   = ENV['DUMP_IP']   || '127.0.0.1'
$local_port = ENV['DUMP_PORT'] || 50002

if ARGV.length > 0
  if ARGV[0].include?(':')
    local_IP_and_port  = ARGV[0].split(':')
    $local_IP          = local_IP_and_port[0]
    $local_port        = local_IP_and_port[1].to_i
  else
    $stderr.puts
    $stderr.puts "Usage: #{$0} [IP:PORT]"
    $stderr.puts "Command line parameters over-rides system environment variables: DUMP_IP and DUMP_PORT"
    $stderr.puts "Default is #{$local_IP}:#{$local_port} if no command line parameters or system environment variables are set."
    $stderr.puts
    exit -1
  end
end

require 'rubygems'
require 'eventmachine'
require 'string_mods'
require 'pp'

class DataDumper < EM::Protocols::LineAndTextProtocol
  def initialize
    $stderr.puts "#{self.class} from #{$local_IP}:#{$local_port}"
    $stderr.puts "Control-C to terminate."
  end

  def receive_data(data)
    
    puts data.to_hex

  end ## end of def receive_data(data)

private
  
  def abort
    EventMachine.stop_server $this_connection
    EventMachine::add_timer( 1 ) { EventMachine.stop }
  end
  
end

EventMachine::run {
  $this_connection = EventMachine::connect $local_IP, $local_port, DataDumper
}


