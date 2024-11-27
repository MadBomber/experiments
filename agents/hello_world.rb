# experiments/agents/hello_world.rb

require 'json'
require 'json_schema'

require_relative 'ai_agent'
require_relative 'hello_world_request'

class HelloWorld < AiAgent::Base
  REQUEST_SCHEMA = HelloWorldRequest.schema

  def receive_request(request_body:)
    # Validate the incoming request body against the schema
    validation_errors = validate_request(request_body)
    
    if validation_errors.any?
      logger.error "Validation errors: #{validation_errors}"
      send_response(
        { error: "Invalid request", details: validation_errors },
        response_uuid
      )
      return
    end

    # TODO: get the from_uuid and envent_id elements from the
    #       request_body header element

    # TODO: get the greeting and the name from the request_body
    

    # Process the request and generate a response
    response = {
      event_id: event_id,
      result: "hello world"  # Replace with actual processing logic
    }

    send_response(response, response_uuid)
  end


  def receive_response(event_id:, response_uuid:)
    nil
  end

  private
  def validate_request(request_body)
    # Use the json_schema gem to validate the request body against the defined schema
    validator = JSONSchema::Validator.new(REQUEST_SCHEMA)
    
    begin
      validator.validate(request_body)
      [] # No errors
    rescue JSONSchema::ValidationError => e
      e.messages # Return validation error messages
    end
  end

end

# Example usage
agent = HelloWorld.new(name: "hello_world", capabilities: ["world greeter", "person greeter"])
agent.run # Starts listening for AMQP messages
