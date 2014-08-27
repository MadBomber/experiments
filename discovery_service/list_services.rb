#!/usr/bin/env ruby -w
# list_services.rb
# List all of the services the RingServer knows about

require 'rinda/ring'

DRb.start_service

ring_server = Rinda::RingFinger.primary
services = ring_server.read_all [:name, nil, nil, nil]

puts "Services on #{ring_server.__drburi}"
services.each do |service|
  puts "#{service[1]} on #{service[2].__drburi} - #{service[3]}"
end