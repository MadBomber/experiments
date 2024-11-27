# experiments/agents/hello_world.rb

require_relative 'ai_agent'

class HelloWorld < AiAgent::Base
  def receive_request(event_id:, response_uuid:)
    # Process the request and generate a response
    response = {
      event_id: event_id,
      result: "hello world"  # Replace with actual processing logic
    }

    send_response(response, response_uuid)
  end
end

# Example usage
agent = HelloWorld.new(name: "hello_world", capabilities: ["world greeter", "person greeter"])
agent.run # Starts listening for AMQP messages
