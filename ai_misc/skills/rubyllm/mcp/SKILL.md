---
name: rubyllm/mcp
version: 1.0.0
description: |
  Model Context Protocol (MCP) client for RubyLLM. Use this skill when connecting RubyLLM to MCP servers for tools, resources, and prompts. Supports stdio, HTTP streaming, and SSE transports with OAuth 2.1 authentication.
---

# RubyLLM::MCP v1.0.0

**MCP for Ruby and RubyLLM**

Ruby client for the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/), built to work with RubyLLM. Use MCP tools, resources, and prompts from your RubyLLM chats.

**Gem Version:** 1.0.0  
**Protocol:** 2025-06-18 (stable), 2026-01-26 (draft)  
**GitHub:** https://github.com/patvice/ruby_llm-mcp

## Installation

```bash
gem 'ruby_llm-mcp'
```

## Quick Start

```ruby
require "ruby_llm/mcp"

RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
end

# Create MCP client
client = RubyLLM::MCP.client(
  name: "filesystem",
  transport_type: :stdio,
  config: {
    command: "bunx",
    args: ["@modelcontextprotocol/server-filesystem", Dir.pwd]
  }
)

# Use MCP tools with RubyLLM
chat = RubyLLM.chat(model: "gpt-4.1-mini")
chat.with_tools(*client.tools)

chat.ask("Find Ruby files modified today and summarize what changed.")
```

## Transports

### STDIO (Local Processes)

```ruby
client = RubyLLM::MCP.client(
  name: "filesystem",
  transport_type: :stdio,
  config: {
    command: "npx",
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/files"]
  }
)
```

### HTTP Streaming

```ruby
client = RubyLLM::MCP.client(
  name: "my-server",
  transport_type: :http_stream,
  config: {
    url: "http://localhost:3001/mcp"
  }
)
```

### SSE (Server-Sent Events)

```ruby
client = RubyLLM::MCP.client(
  name: "my-server",
  transport_type: :sse,
  config: {
    url: "http://localhost:3001/sse"
  }
)
```

## Tools

```ruby
# Get available tools
client.tools.each do |tool|
  puts tool.name
  puts tool.description
  puts tool.input_schema
end

# Use with RubyLLM
chat = RubyLLM.chat
chat.with_tools(*client.tools)
chat.ask("List files in current directory")
```

## Resources

```ruby
# List available resources
client.resources.each do |resource|
  puts resource.uri
  puts resource.name
  puts resource.description
end

# Read a resource
resource = client.resource("release_notes")
chat = RubyLLM.chat
chat.with_resource(resource)
chat.ask("Summarize release notes in 5 bullet points")
```

## Prompts

```ruby
# List available prompts
client.prompts.each do |prompt|
  puts prompt.name
  puts prompt.arguments
end

# Use a prompt
prompt = client.prompt("code_review")
chat = RubyLLM.chat

response = chat.ask_prompt(
  prompt,
  arguments: {
    language: "ruby",
    focus: "security"
  }
)
```

## Handlers & Notifications

```ruby
# Progress notifications
client.on_progress do |progress|
  puts "Progress: #{progress.progress}% - #{progress.message}"
end

# Logging notifications
client.on_logging do |logging|
  puts "[#{logging.level}] #{logging.message}"
end

# Resource updates
client.on_resource_updated do |uri|
  puts "Resource updated: #{uri}"
end

# Tool calls
chat = RubyLLM.chat
chat.with_tools(*client.tools)
chat.ask("Run a repository scan") do |chunk|
  print chunk.content
end
```

## OAuth 2.1 Authentication

### Rails Setup (Per-User)

```ruby
# config/routes.rb
mount RubyLLM::MCP::OAuth::Engine, at: "/mcp/oauth"

# app/controllers/mcp_connections_controller.rb
class McpConnectionsController < ApplicationController
  def create
    client = RubyLLM::MCP.client(
      name: "github",
      transport_type: :http_stream,
      config: { url: "https://api.github.com/mcp" },
      oauth: {
        client_id: ENV["GITHUB_MCP_CLIENT_ID"],
        client_secret: ENV["GITHUB_MCP_CLIENT_SECRET"],
        redirect_uri: mcp_oauth_callback_url
      }
    )
    
    # Redirect user to authorization
    redirect_to client.oauth_authorization_url
  end
  
  def callback
    client.complete_oauth(params[:code])
    # Save client.connection for current_user
  end
end
```

### CLI Setup (Browser Flow)

```ruby
client = RubyLLM::MCP.client(
  name: "github",
  transport_type: :http_stream,
  config: { url: "https://api.github.com/mcp" },
  oauth: {
    client_id: ENV["GITHUB_MCP_CLIENT_ID"],
    redirect_uri: "http://localhost:3000/callback"
  }
)

# Opens browser for authorization
client.oauth_interactive_auth
```

## Protocol Tracks

```ruby
# Stable track (default)
client = RubyLLM::MCP.client(
  name: "server",
  protocol_track: :stable  # 2025-06-18
)

# Draft track
client = RubyLLM::MCP.client(
  name: "server",
  protocol_track: :draft  # 2026-01-26
)
```

## Common MCP Servers

### Filesystem

```bash
npx @modelcontextprotocol/server-filesystem /path/to/files
```

```ruby
client = RubyLLM::MCP.client(
  name: "filesystem",
  transport_type: :stdio,
  config: {
    command: "npx",
    args: ["@modelcontextprotocol/server-filesystem", Rails.root]
  }
)
```

### GitHub

```bash
npx @modelcontextprotocol/server-github
```

### PostgreSQL

```bash
npx @modelcontextprotocol/server-postgres postgres://localhost/mydb
```

### Git

```bash
npx @modelcontextprotocol/server-git
```

## Error Handling

```ruby
begin
  client = RubyLLM::MCP.client(...)
  client.tools
rescue RubyLLM::MCP::ConnectionError => e
  Rails.logger.error "MCP connection failed: #{e.message}"
rescue RubyLLM::MCP::ProtocolError => e
  Rails.logger.error "MCP protocol error: #{e.message}"
end
```

## See Also

- **Main RubyLLM**: [rubyllm](../SKILL.md)
- **Tools**: [tools](../tools/SKILL.md)
- **MCP Spec**: https://modelcontextprotocol.io
