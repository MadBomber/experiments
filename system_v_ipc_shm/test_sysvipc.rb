#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: test_sysvipc.rb
##  Desc: Do some testing of RUby's Kernel#fork and SysVIPC
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'SysVIPC'

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




# All IPC objects are identified by a key. SysVIPC includes a
# convenience function for mapping file names and integer IDs into a
# key:

an_existing_filename  = 'shared_memory.txt'
key                   = SysVIPC.ftok(an_existing_filename, 0)


# Get (create if necessary) a message queue:

mq = SysVIPC::MessageQueue.new(key, SysVIPC::IPC_CREAT | 0600)


# Get (create if necessary) an 8192-byte shared memory region:

sh = SysVIPC::SharedMemory.new(key, 8192, SysVIPC::IPC_CREAT | 0660)
#
# Attach shared memory:

shmaddr = sh.attach


debug_me(tag: "master:#{Process.pid}", header: false){[ :key, :mq, :sh, :shmaddr ]}



workers = []

configatron.workers.times do |x|
  workers << spawn(RbConfig.ruby, "worker.rb", an_existing_filename)
  Process.detach workers.last
end

=begin
# The shared memory stuff sucks.

sleep(configatron.workers)

configatron.workers.times do |x|

  # Send a message of type 0:
  # NOTE: Documentation is wrong; type == 1 is for text

  mq.send(1, "hello world ##{x}")

end


# This shaared memory stuff is junk

# Write data:

workers.each do |w|
  shmaddr.write("#{w},quit\n")
  debug_me(tag: "master:#{Process.pid} worker: #{w} send quit", header: true)
  data = ''
  until 'okay' == data
    data = shmaddr.read(4)
    debug_me(tag: "master:#{Process.pid} worker: #{w} waiting for quit", header: false){[ :data ]}
  end
  debug_me(tag: "master:#{Process.pid} worker: #{w} acknowledged quit", header: true)
end

# Detach shared memory:

sh.detach(shmaddr)

=end

puts <<~EOS

The shared memory capability sucks.  Ruby's inability to anchor an object
to a specific memory address precludes the use of shm for IPC work.  The
unix IPC message queque works okay.

Currently the workers are spinning their wheels crunching random numbers.  To
see the multi-core activity launch 'htop' in a terminal window.  You can
get htop via 'brew install htop' - its cross platform unix utility.

To terminate all the workers use 'killall ruby'



EOS
