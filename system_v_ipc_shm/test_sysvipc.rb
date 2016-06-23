#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: test_sysvipc.rb
##  Desc: Do some testing of RUby's Kernel#fork and SysVIPC
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'
configatron.valid_workers_range = (2..8)

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

workers = []

configatron.workers.times do |x|
  workers << spawn(RbConfig.ruby, "-eputs;puts'Hello, world!  I am number #{x}';sleep(5)")
  Process.detach workers.last
end

ap workers
puts `ps aux | fgrep ruby`

