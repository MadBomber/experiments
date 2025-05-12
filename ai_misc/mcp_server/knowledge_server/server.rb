#!/usr/bin/env ruby
# examples/fast_mcp_server/server.rb

require 'fast-mcp'
require_relative 'tools/knowledge_retriever'

# Create a new MCP server instance
server = FastMcp::Server.new(
  name: 'aia-knowledge-server',
  version: '1.0.0',
  description: 'An MCP server providing knowledge retrieval capabilities'
)

# Register the KnowledgeRetriever tool
server.register_tool(KnowledgeRetriever)

# Define configuration for the server
config = {
  # Set to true in production for security
  authentication: false,
  
  # Set to 'http' for HTTP transport or 'stdio' for STDIO transport
  transport_type: 'http',
  
  # HTTP transport specific settings (only used if transport_type is 'http')
  port: 3000,
  host: 'localhost'
}

# Start the server with the specified configuration
puts "Starting AIA Knowledge Server on #{config[:host]}:#{config[:port]}..."
puts "Access the server at http://#{config[:host]}:#{config[:port]}"
server.start(config)
