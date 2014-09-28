#!/bin/env ruby
# Here is an example of a server that counts lines of input from the remote peer and
# sends back the total number of lines received, after each line. Try the example with
# more than one client connection opened via telnet, and you will see that the line count
# increments independently on each of the client connections. Also very important to note,
# is that the handler for the receive_data function, which our handler redefines, may not
# assume that the data it receives observes any kind of message boundaries. Also, to use
# this example, be sure to change the server and port parameters to the start_server call
# to values appropriate for your environment.

require 'rubygems'
require 'eventmachine'

module LineCounter

  MaxLinesPerConnection = 10

  def post_init
    puts "Received a new connection"
    @data_received = ""
    @line_count = 0
  end

  def receive_data data
    @data_received << data
    while @data_received.slice!( /^[^\n]*[\n]/m )
      @line_count += 1
      send_data "received #{@line_count} lines so far\r\n"
      @line_count == MaxLinesPerConnection and close_connection_after_writing
    end
  end

end # module LineCounter

EventMachine::run {
  host,port = "localhost", 8090
  EventMachine::start_server host, port, LineCounter
  puts "Now accepting connections on address #{host}, port #{port}..."
  EventMachine::add_periodic_timer( 10 ) { $stderr.write "*" }
}

