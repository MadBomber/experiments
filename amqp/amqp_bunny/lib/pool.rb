require 'consumer'

class Pool
  attr_accessor :connection, :num_threads

  def initialize(num_threads = nil, options=OPTIONS)
    @num_threads = num_threads.to_i || 2
    @connection = Bunny.new options
  end

  def init
    connection.start
    process
  end


  def process
    queue.subscribe(block: true) do |delivery_info, properties, payload|
      pool.future.process(payload)
    end
  end

  def channel
    @channel ||= connection.create_channel
  end

  def queue
    @queue ||= channel.queue('payments', durable: true, auto_delete: false)
  end

  def pool
    @pool ||= Consumer.pool(size: num_threads, args: [connection])
  end
end
