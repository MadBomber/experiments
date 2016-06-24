#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: test_sysvmq.rb
##  Desc: Do some testing of RUby's Kernel#fork and sysvmq
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'sysvmq'

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'
configatron.valid_workers_range = (2..16)

HELP = <<EOHELP
Important:

  Valid workers range: #{configatron.valid_workers_range}

EOHELP

cli_helper("Do some testing of RUby's Kernel#fork and SysVIPC") do |o|
  o.int     '-w', '--workers',    "No. of workers - valid range: #{configatron.valid_workers_range}",   default: 2
end

# Display the usage info
unless  configatron.arguments.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

unless configatron.valid_workers_range.include? configatron.workers
  error "Number of workers (#{configatron.workers }) is outside the valid range: #{configatron.valid_workers_range}"
end


abort_if_errors


######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?







# Create a message queue with a 1024 byte buffer.
key   = 0xDEADC0DE
mq    = SysVMQ.new(key, 1024, SysVMQ::IPC_CREAT | 0666)

debug_me(tag: "master:#{Process.pid}", header: false){[ :key, :mq ]}



workers = []

configatron.workers.times do |x|
  workers << spawn(RbConfig.ruby, "worker_sysvmq.rb", key.to_s)
  Process.detach workers.last
end


workers.size.times do |x|
  ('A'..'D').each {|letter| mq.send "Hellø Wårld! ##{x} #{letter}"}
end

while mq.stats[:count] > 0
  sleep(1)
end

debug_me(tag: "master:#{Process.pid}", header: false){[ :count ]}

__END__
assert_equal 1, mq.stats[:count]

assert_equal "Hellø Wårld!", mq.receive.force_encoding("UTF-8")

# Raise an exception instead of blocking until a message is available
mq.receive(0, SysVMQ::IPC_NOWAIT)

ensure
# Delete queue
mq.destroy


