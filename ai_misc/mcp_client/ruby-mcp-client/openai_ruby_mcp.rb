#!/usr/bin/env ruby
# frozen_string_literal: true

# MCPClient integration example using the openai/openai-ruby gem
require 'mcp_client'
require 'bundler/setup'
require 'openai'
require 'json'

require 'debug_me'
include DebugMe

$DEBUG_ME = true

# Ensure the OPENAI_API_KEY environment variable is set
api_key = ENV.fetch('OPENAI_API_KEY', nil)
abort 'Please set OPENAI_API_KEY' unless api_key

# Create an MCPClient client (stdio stub for demo)
logger = Logger.new($stdout)
logger.level = Logger::WARN
mcp_client = MCPClient::Client.new(
  mcp_server_configs: [
    MCPClient.stdio_config(
      command: %W[npx -y @modelcontextprotocol/server-filesystem #{Dir.pwd}]
    )
  ],
  logger: logger
)

debug_me{[ :mcp_client ]}


# Initialize the OpenAI client
client = OpenAI::Client.new(access_token: api_key)

debug_me{[ :client ]}

# Convert MCPClient tools to OpenAI function specs
tools = mcp_client.to_openai_tools

debug_me{[ :tools ]}

# Build initial chat messages
messages = [
  { role: 'system', content: 'You can call filesystem tools.' },
  { role: 'user', content: 'List all files in current directory' }
]

debug_me{[ :messages ]}

# 1) Send chat with function definitions
response = client.chat.completions.create(
  model: 'gpt-4o-mini',
  messages: messages,
  tools: tools
)

debug_me{[ :response ]}

# Extract function call details
message       = response.choices[0].message[:tool_calls][0]
function_call = message[:function]
name          = function_call[:name]
args          = JSON.parse(function_call[:arguments])

# 2) Invoke the MCPClient tool
result = mcp_client.call_tool(name, args)

debug_me{[ :result ]}

# 3) Add function call + result to conversation
messages << { role: 'assistant', tool_calls: [message] }
messages << { role: 'tool', tool_call_id: message[:id], name: name, content: result.to_json }

debug_me{[ :messages ]}

# 4) Get final response from the model
final = client.chat.completions.create(
  model: 'gpt-4.1-mini',
  messages: messages
)

debug_me{[ :final ]}

puts final.choices[0].message.content
