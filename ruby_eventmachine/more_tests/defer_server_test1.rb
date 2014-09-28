#!/usr/bin/env ruby

require 'eventmachine'

module Server1
  def post_init
    puts "-- someone connected to the server"
  end

  def receive_data(data)
    puts data

    operation = proc {
      # calculations
      puts response
      response = response+"\r\n"
    }
    callback = proc { |response|
      send_data(response)
    }

    EventMachine.defer(operation, callback)
  end

  def unbind
    puts "-- someone closed the connection to the server"
  end
end

EventMachine.run { EventMachine.start_server 'localhost', 8080, Server1 } 

