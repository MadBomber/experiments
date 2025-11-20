#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating MCPClient with Playwright MCP server via Server-Sent Events (SSE)
#

url = "https://news.google.com"

puts <<~EOS

  Usage:
  1. Start Playwright MCP server: npx @playwright/mcp@latest --port 8931
  2. Run this example: ruby mcp_sse_server_example.rb

EOS

require 'debug_me'
include DebugMe
$DEBUG_ME = true

require 'mcp_client'
require 'bundler/setup'
require 'json'
require 'logger'

# Create a logger for debugging (optional)
logger       = Logger.new($stdout)
logger.level = Logger::INFO

# Create an MCP client that connects to the Playwright MCP server over SSE
# The server definition is loaded from a JSON file for better maintainability
sse_client = MCPClient.create_client(server_definition_file: './playwright_server_definition.json')

puts 'Connected to Playwright MCP server with SSE transport'

# List all available tools
tools = sse_client.list_tools
puts "Found #{tools.length} tools:"
tools.each do |tool|
  puts "- #{tool.name}: #{tool.description&.split("\n")&.first}"
end

# Find tools by name pattern (supports string or regex)
browser_tools = sse_client.find_tools(/browser/)
puts "\nFound #{browser_tools.length} browser-related tools"

# Launch a browser
puts "\nLaunching browser..."
sse_client.call_tool('browser_install', {})
puts 'Browser installed'
sse_client.call_tool('browser_navigate', { url: 'about:blank' })
# No browser ID needed with these tool names
puts 'Browser launched and navigated to blank page'

# Create a new page
puts "\nCreating a new page..."
sse_client.call_tool('browser_tab_new', {})
# No page ID needed with these tool names
puts 'New tab created'

# Navigate to a website
puts "\nNavigating to a website..."
sse_client.call_tool('browser_navigate', { url: url })
puts 'Navigated to example.com'

# Get page title
puts "\nGetting page title..."
title_result = sse_client.call_tool('browser_snapshot', {})
puts "Page title: #{title_result}"

# Take a screenshot
puts "\nTaking a screenshot..."
sse_client.call_tool('browser_take_screenshot', {})
puts 'Screenshot captured successfully'

# Close browser
puts "\nClosing browser..."
sse_client.call_tool('browser_close', {})
puts 'Browser closed'

# Ping the server to check connectivity
puts "\nPinging server:"
begin
  ping_result = sse_client.ping
  puts "Ping successful: #{ping_result.inspect}"
rescue StandardError => e
  puts "Ping failed: #{e.message}"
end

# Clean up connections
sse_client.cleanup
puts "\nConnection cleaned up"
