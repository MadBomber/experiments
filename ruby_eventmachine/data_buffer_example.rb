#!/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'pp'

class DataBuffer < EM::Protocols::LineAndTextProtocol
  def initialize
    puts "init'ing new instance of #{self.class.to_s}"
    puts "send 'quit' to terminate."
    @line_ctr = 0
    @databuf = []
  end

  def receive_data(data)
    if data.include? "quit"
      if @line_ctr > 0
        send_data(@databuf.to_s)
        send_data("Done.\r\n")
      end
      abort
    else
      @databuf << data
      @line_ctr += 1
      if data == ".\r\n" || @line_ctr == 10
        if data == ".\r\n"
          @databuf.pop
        end
        send_data(@databuf.to_s)
        reset_databuf()
      end
    end
  end

private
  
  def reset_databuf
    @line_ctr = 0
    @databuf = []
  end
  
  def abort
    EventMachine.stop_server $this_server
    EventMachine::add_timer( 1 ) { EventMachine.stop }
  end
  
end

EventMachine::run {
  $this_server = EventMachine::start_server "127.0.0.1", 8081, DataBuffer
}
