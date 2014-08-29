#!/usr/bin/env ruby -w
# rinda_ts.rb
# Registering a TupleSpace with Rinda::Ring

require 'rinda/ring'
require 'rinda/tuplespace'

DRb.start_service

ts = Rinda::TupleSpace.new

provider = Rinda::RingProvider.new :TupleSpace, ts, 'Tuple Space'
provider.provide

DRb.thread.join
