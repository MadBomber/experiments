#!/usr/bin/ruby
# use_a_tuplespace.rb

require 'rinda/ring' # for RingFinger

require 'rinda/tuplespace' # for TupleSpaceProxy

DRb.start_servicering_server = Rinda::RingFinger.primary

# Ask the RingServer for the advertised TupleSpace.

ts_service = ring_server.read([:name, :TupleSpace, nil, nil])[2]
tuplespace = Rinda::TupleSpaceProxy.new(ts_service)

# Now we can use the object normally:

tuplespace.write([:data, rand(100)])

puts "Data is #{tuplespace.read([:data, nil]).last}."

# Data is 91.
