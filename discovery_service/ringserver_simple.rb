#!/usr/bin/env ruby -w
# ringserver.rb
# Rinda RingServer

require 'rinda/ring'
require 'rinda/tuplespace'

# start DRb
DRb.start_service

# Create a TupleSpace to hold named services, and start running
Rinda::RingServer.new Rinda::TupleSpace.new

# Wait until the user explicitly kills the server.
DRb.thread.join
