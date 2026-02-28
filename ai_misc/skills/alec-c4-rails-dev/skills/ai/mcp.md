# Building MCP Servers in Rails

> **Goal:** Expose your Rails app capabilities to AI agents (Claude, Cursor).
> **Gem:** `model-context-protocol-rb` (or custom implementation via SSE).

## 1. Concept
Your Rails app becomes a tool provider.
- **Resources:** Expose DB records (e.g., `projects://1/tasks`).
- **Tools:** Expose Actions (e.g., `create_task`, `refund_order`).
- **Prompts:** Pre-defined templates.

## 2. Implementation (SSE Controller)
MCP works over Stdio or SSE (Server-Sent Events). For Rails, SSE is natural.

```ruby
# app/controllers/mcp_controller.rb
class McpController < ActionController::Base
  include ActionController::Live

  def connect
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream)
    
    # Handle JSON-RPC handshake
    # ... implementation details ...
  end
end
```

## 3. Defining Tools
Wrap your Interactions as Tools.

```ruby
Mcp::Tool.define(:create_user) do |t|
  t.description = "Creates a new user"
  t.param :email, type: :string
  
  t.execute do |params|
    Users::Create.run!(params).as_json
  end
end
```
