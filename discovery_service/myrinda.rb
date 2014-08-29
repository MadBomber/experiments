# pretend this is in "myrinda.rb"
require 'rinda/ring'

def tuplespace
  DRb.start_service

  # Fetch the first TupleSpace
  Rinda::RingFinger.primary 
end

ts = tuplespace
