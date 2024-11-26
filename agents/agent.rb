#!/usr/bin/env ruby
# ~/experiments/agents/agent.rb
#
# TODO: consider consul, zookeeper, etcd
#

require "bunny"
require "json"
require "net/http"
require "uri"

class Agent
  attr_reader :id, :capabilities

  def initialize(name:, capabilities:)
    @name = name
    @capabilities = capabilities
  end

  def run(*args)
    puts "Agent #{@name} ran with args: #{args.inspect}"
  end

  def register
    uri = URI.parse("http://localhost:4567/register")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = { name: @name, capabilities: @capabilities }.to_json

    response = http.request(request)
    @id = JSON.parse(response.body)["uuid"] # Extract the UUID from the JSON response
    puts "Registered Agent #{@name} with ID: #{@id}"
  end

  def discover(capability)
    uri = URI.parse("http://localhost:4567/discover?capability=#{capability}")
    response = Net::HTTP.get_response(uri)

    puts "Agents providing #{capability}: #{response.body}"
  end

  def withdraw
    return puts "Agent not registered" unless @id

    uri = URI.parse("http://localhost:4567/withdraw/#{@id}")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Delete.new(uri.path)
    
    response = http.request(request)
    
    if response.code.to_i == 204
      puts "Successfully withdrew Agent #{@name}."
      @id = nil # Reset the ID to indicate that the agent is no longer registered
    elsif response.code.to_i == 404
      puts "Error: #{JSON.parse(response.body)['error']}"
    end
  end
end

# Example usage
agent = Agent.new(name: "agent_1", capabilities: ["image_processing", "data_analysis"])
agent.register
puts agent.discover("image_processing")
sleep 15
agent.withdraw

