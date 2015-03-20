#!/usr/bin/env ruby
# rindac.rb
# rindac.rb modified to find the TupleSpace via a RingServer

require 'rinda/ring'

def do_it(v)
  puts "do_it(#{v})"
  v + v
end

DRb.start_service
ring_server = Rinda::RingFinger.primary

ts = ring_server.read([:name, :TupleSpace, nil, nil])[2]
ts = Rinda::TupleSpaceProxy.new ts

(1..10).each do |n|
  ts.write(['sum', DRb.uri, n])
end

(1..10).each do |n|
  ans = ts.take(['ans', DRb.uri, n, nil])
  p [ans[2], ans[3]]
end
