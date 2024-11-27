# experiments/agents/ai_agent/message_client.rb

require 'bunny'
require 'json'
require 'json_schema'

class AiAgent::MessageClient
  QUEUE_TTL = 60_000 # 60 seconds TTL

  attr_accessor :logger

  def initialize(logger: Logger.new($stdout))
    @connection = create_amqp_connection
    @channel    = @connection.create_channel
    @logger     = logger
  end


  def create_queue(agent_id, type)
    queue_name = "#{agent_id}.#{type}"
    @channel.queue(queue_name, expires: QUEUE_TTL)
  end

  def listen_for_messages(queue, request_handler:, response_handler:)
    queue.subscribe(block: true) do |delivery_info, properties, body|
      message = JSON.parse(body)
      logger.debug "Received message: #{message.inspect}"

      case message["type"]
      when "request"
        request_handler.call(message)
      when "response"
        response_handler.call(message)
      else
        raise NotImplementedError
      end
    end
  end

  private

  def create_amqp_connection
    Bunny.new.tap(&:start)
  rescue Bunny::TCPConnectionFailed => e
    logger.error "Failed to connect to AMQP: #{e.message}"
    exit 1
  end
end
