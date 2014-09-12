require 'bunny'
require 'msgpack'
require 'json'
require 'celluloid/autostart'

class Consumer
  include Celluloid

  finalizer :exit
  attr_reader :connection, :channel, :queue

  def initialize(connection)
    @connection = connection
  end


  def process(payload)
    msg = MessagePack.unpack(payload)
    value = msg['params']['value']
    $stdout.print "From: #{Thread.current} #{value}\n"
  end

  def exit
    $stdout.print "Exit from #{Thread.current}\n"
    # channel.close    # TDV channel is nil
  end

end
