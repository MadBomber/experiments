require 'bunny'
require 'msgpack'

class Producer
  attr_reader :connection, :channel, :queue, :messages

  def initialize(messages = 100, options=OPTIONS)
    @messages = messages
    connect options
  end

  def connect(options)
    # Create and start the connection with RabbitMQ
    @connection = Bunny.new options
    @connection.start

    # Create a channel
    @channel = @connection.create_channel
    # Create a queue with default_exchange, 'direct exchange'
    @queue = @channel.queue('payments', durable: true, auto_delete: false)
  end

  private :connect

  def run
    puts "Publishing..."
    messages.times do |i|
      message = create_message(i)
      queue.publish(message, routing_key: 'payments')
    end
    puts "Published!"
  end

  def create_message(value)
    { type: 'payment',
      params: {
        value: value
      }
    }.to_msgpack
  end
end
