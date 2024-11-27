#!/usr/bin/env ruby
# experiments/agents/ai_agent/base.rb

require 'logger'

require_relative 'registry_client'
require_relative 'message_client'

class AiAgent::Base
  attr_reader :id, :capabilities, :name
  attr_accessor :registry_client, :message_client

  def initialize(
      capabilities:,    # TODO: make a ?constant? in the sub-class
      registry_client:  RegistryClient.new, 
      message_client:   MessageClient.new,
      logger: Logger.new($stdout)
    )
    @name             = self.class.name
    @capabilities     = capabilities
    @id               = nil
    @registry_client  = registry_client
    @message_client   = message_client
    @logger           = logger
  end

  def run
    logger.info "Agent #{@name} is running"
    register
    start_amqp_listener
  end


  def register
    @id = registry_client.register(name: @name, capabilities: @capabilities)
    logger.info "Registered Agent #{@name} with ID: #{@id}"
  rescue StandardError => e
    logger.error "Error during registration: #{e.message}"
  end


  def withdraw
    registry_client.withdraw(@id) if @id
    @id = nil
  end

  ################################################
  private
  
  def start_amqp_listener
    %w[request].each do |type|
      queue = message_client.create_queue(@id, type)
      message_client.listen_for_messages(
        queue,
        request_handler:  ->(message) { receive_request(event_id: message["event_id"], response_uuid: message["response_uuid"]) },
        response_handler: ->(message) { receive_response(event_id: message["event_id"], response_uuid: message["response_uuid"]) }
      )
    end
  end


  def receive_request(event_id:, response_uuid:)
    raise NotImplementedError, "#{self.class} must implement #receive_request"
  end


  def receive_response(event_id:, response_uuid:)
    raise NotImplementedError, "#{self.class} must implement #receive_response"
  end
end

