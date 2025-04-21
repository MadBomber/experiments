#!/usr/bin/env ruby
# experiments/ai_misc/sinatra_fastmcp_server.rb
# Desc: uses the fast-mcp gem and sintra to create a MCP server


require 'sinatra'
require 'fast_mcp'

# Create the MCP server
mcp_server = FastMcp::Server.new(name: 'sinatra-mcp-server', version: '1.0.0')

# Define your tools
class ExampleTool < Mcp::Tool
  description "An example tool"
  arguments  do
   required(:input).filled(:string).description("Input value")
  end

  def call(input:)
    "You provided: #{input}"
  end
end

# Register resources
class Counter < FastMcp::Resource
  uri "example/counter"
  resource_name "Counter",
  description "A simple counter resource"
  mime_type "application/json"

  def initialize
    @count = 0
  end

  attr_accessor :count

  def content
    JSON.generate({ count: @count })
  end
end


# Use the MCP middleware
use FastMcp::Transports::RackTransport, server

# Define your Sinatra routes
get '/' do
  'Hello, world!'
end
