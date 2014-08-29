#!/usr/bin/env ruby -w
# rindas.rb
# rindas modified to find the TupleSpace via a RingServer

require 'rinda/ring'

def do_it(v)
  puts "do_it(#{v})"
  v + v
end

DRb.start_service
ring_server = Rinda::RingFinger.primary

ts = ring_server.read([:name, :TupleSpace, nil, nil])[2]
ts = Rinda::TupleSpaceProxy.new ts

loop do
  r = ts.take(['sum', nil, nil])
  v = do_it(r[2])
  ts.write(['ans', r[1], r[2], v])
end