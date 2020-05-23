#!/usr/bin/ruby
# share_a_tuplespace.rb

require 'rinda/ring'        # for RingFinger and SimpleRenewer
require 'rinda/tuplespace'  # for TupleSpace

DRb.start_servicering_server = Rinda::RingFinger.primary

# Register our TupleSpace service with the RingServer
ring_server.write( [  :name,
                      :TupleSpace,
                      Rinda::TupleSpace.new,
                      'Tuple Space'
                    ],
                    Rinda::SimpleRenewer.new
                )

DRb.thread.join
