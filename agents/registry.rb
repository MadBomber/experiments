#!/usr/bin/env ruby
# ~/experiments/agents/registry.rb

require 'sinatra'
require 'json'
require 'bunny'
require 'securerandom'

# In-memory registry to store agent capabilities
AGENT_REGISTRY = {}

# Health check endpoint
get '/healthcheck' do
  content_type :json
  { agent_count: AGENT_REGISTRY.size }.to_json
end

# Endpoint to register an agent
post '/register' do
  request.body.rewind
  agent_info = JSON.parse(request.body.read)

  agent_name = agent_info['name']
  capabilities = agent_info['capabilities']

  agent_uuid = SecureRandom.uuid

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

# Endpoint for executing an agent's run method
post '/run/:uuid' do
  uuid = params['uuid']
  request.body.rewind
  args = JSON.parse(request.body.read)

  agent = AGENT_REGISTRY[uuid]
  if agent
    # Simulating agent's processing action
    result = "Agent #{agent[:name]} processed with args: #{args.inspect}"
    content_type :json
    { result: result }.to_json
  else
    status 404
    content_type :json
    { error: "Agent with UUID #{uuid} not found." }.to_json
  end
end

# Withdraw an agent from the registry
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

# Display all registered agents
get '/' do
  content_type :json
  AGENT_REGISTRY.to_json
end

# Start the Sinatra server
if __FILE__ == $PROGRAM_NAME
  Sinatra::Application.run!
end