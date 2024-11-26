#!/usr/bin/env ruby
# ~/experiments/agents/registry.rb

require 'sinatra'
require 'json'
require 'bunny'
require 'securerandom'

# In-memory registry to store agent capabilities
AGENT_REGISTRY = {}

# Endpoint to register an agent
post '/register' do
  request.body.rewind
  agent_info = JSON.parse(request.body.read)

  agent_name = agent_info['name']
  capabilities = agent_info['capabilities']
  
  # Generate a UUID for the agent
  agent_uuid = SecureRandom.uuid

  # Store the agent's information in the registry using the UUID
  AGENT_REGISTRY[agent_uuid] = { name: agent_name, capabilities: capabilities }
  
  status 201
  content_type :json
  { uuid: agent_uuid }.to_json
end

# Endpoint to discover agents by capability
get '/discover' do
  capability = params['capability']
  matching_agents = AGENT_REGISTRY.select do |_, agent|
    agent[:capabilities].include?(capability)
  end

  content_type :json
  matching_agents.transform_values { |agent| agent[:name] }.to_json
end

# Endpoint to withdraw an agent from the registry
delete '/withdraw/:uuid' do
  uuid = params['uuid']
  
  if AGENT_REGISTRY.delete(uuid)
    status 204 # No Content
  else
    status 404 # Not Found
    content_type :json
    { error: "Agent with UUID #{uuid} not found." }.to_json
  end
end


# Endpoint to display all registered agents
get '/' do
  content_type :json
  AGENT_REGISTRY.to_json
end

# Start the Sinatra server
if __FILE__ == $PROGRAM_NAME
  Sinatra::Application.run!
end

__END__

# Register an agent
curl -X POST -H "Content-Type: application/json" -d '{"name": "Agent One", "capabilities": ["capability1", "capability2"]}' http://localhost:4567/register

# Discover agents
curl "http://localhost:4567/discover?capability=capability1"

# Show current registry
curl http://localhost:4567/
