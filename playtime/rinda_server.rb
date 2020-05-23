#!/usr/bin/ruby
# rinda_server.rb

require 'rinda/ring'       # for RingServer
require 'rinda/tuplespace' # for TupleSpace

DRb.start_service

# Create a TupleSpace to hold named services, and start running.
Rinda::RingServer.new(Rinda::TupleSpace.new)

DRb.thread.join
