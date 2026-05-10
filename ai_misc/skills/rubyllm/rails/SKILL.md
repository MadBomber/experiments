---
name: rubyllm-rails
description: |
  Rails integration for RubyLLM. Use this skill when setting up ActiveRecord-backed chats, Hotwire/Turbo streaming, background job processing, chat UI generation, agents in Rails, file attachments with ActiveStorage, and multi-tenant LLM contexts.
allowed-tools:
  - Bash(bundle *)
  - Bash(bin/rails *)
---

# RubyLLM Rails Integration

Rails + AI made simple. Persist chats with ActiveRecord. Stream with Hotwire.

## Installation

```bash
bundle add ruby_llm
bin/rails generate ruby_llm:install
bin/rails db:migrate
bin/rails ruby_llm:load_models

# Optional: Add chat UI
bin/rails generate ruby_llm:chat_ui
# Visit http://localhost:3000/chats
```

## Models

### Chat Model

```ruby
class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :user
  
  scope :recent, -> { order(updated_at: :desc) }
  
  def title
    messages.first&.content&.truncate(30) || "New Chat"
  end
end
```

### Message Model

```ruby
class Message < ApplicationRecord
  acts_as_message
  broadcasts_to ->(message) { "chat_#{message.chat_id}" }
  
  has_many_attached :attachments
  
  # Don't validate content presence (empty assistant messages created during streaming)
  validates :role, presence: true
  validates :chat, presence: true
end
```

### Model Registry

```ruby
class Model < ApplicationRecord
  acts_as_model
  has_many :chats
  
  scope :with_vision, -> { where(supports_vision: true) }
end

# Usage
Chat.joins(:model).where(models: { provider: 'anthropic' })
```

## Basic Usage

```ruby
# Create chat
chat = Chat.create!(model: 'gpt-5-nano', user: current_user)

# Ask question
response = chat.ask "Hello!"

# Continue conversation
chat.ask "Tell me more"

# Check messages
chat.messages.count  # => 4 (2 user + 2 assistant)
```

### System Instructions

```ruby
chat.with_instructions "You are a Ruby expert"
chat.with_instructions("Use short examples", append: true)
```

### File Attachments

```ruby
chat.ask "What's in this?", with: "path/to/file.pdf"
chat.ask "Analyze", with: ["image.jpg", "document.pdf", "data.csv"]
chat.ask "Process", with: params[:uploaded_file]
```

> **v1.15+:** Active Storage blobs are reused instead of re-downloaded/re-uploaded on each ask,
> reducing API overhead when the same attachment is referenced multiple times.

### Structured Output

```ruby
class ProductSchema < RubyLLM::Schema
  string :name
  number :price
  array :features, of: :string
end

chat.with_schema(ProductSchema)
response = chat.ask "Analyze this product"
puts response.content  # Hash
```

## Hotwire Streaming

### Background Job

```ruby
class ChatStreamJob < ApplicationJob
  queue_as :default

  def perform(chat_id)
    chat = Chat.find(chat_id)
    
    chat.complete do |chunk|
      message = chat.messages.last
      message&.broadcast_append_chunk(chunk.content) if message
    end
  end
end
```

### Controller

```ruby
class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    
    # Save user message immediately
    @chat.add_message(role: :user, content: params[:content])
    
    # Process AI in background
    ChatStreamJob.perform_later(@chat.id)
    
    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to @chat }
    end
  end
end
```

### View

```erb
<%= turbo_stream_from "chat_#{@chat.id}" %>

<div id="messages" data-controller="message-ordering">
  <%= render @chat.messages %>
</div>

<%= form_with(url: chat_messages_path(@chat), method: :post) do |f| %>
  <%= f.text_area :content %>
  <%= f.submit "Send" %>
<% end %>
```

### Message Ordering (Stimulus)

```javascript
// app/javascript/controllers/message_ordering_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.reorderMessages()
    this.observeNewMessages()
  }

  observeNewMessages() {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((m) => {
        m.addedNodes.forEach((node) => {
          if (node.matches?.('[data-message-ordering-target="message"]')) {
            setTimeout(() => this.reorderMessages(), 10)
          }
        })
      })
    })
    observer.observe(this.element, { childList: true, subtree: true })
  }

  reorderMessages() {
    Array.from(this.messageTargets)
      .sort((a, b) => new Date(a.dataset.createdAt) - new Date(b.dataset.createdAt))
      .forEach((msg) => this.element.appendChild(msg))
  }
}
```

## Agents in Rails

```ruby
class SupportAgent < RubyLLM::Agent
  chat_model Chat
  model "gpt-5-nano"
  instructions
  tools SearchDocs, CreateTicket
end

# Controller
class SupportController < ApplicationController
  def create
    @chat = SupportAgent.create!(user: current_user)
    @chat.ask(params[:message])
    redirect_to @chat
  end
end
```

## Multi-Tenant Setup

```ruby
class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :tenant
  
  after_find :set_tenant_context
  
  private
  
  def set_tenant_context
    self.context = RubyLLM.context do |config|
      config.openai_api_key = tenant.openai_api_key
    end
  end
end
```

## Configuration

```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  
  # Use new acts_as API
  config.use_new_acts_as = true
end
```

### Fiber-Safe (Rails 7.2.1+ / 8.x)

```ruby
# config/application.rb
config.active_support.isolation_level = :fiber
```

## Custom Model Names

```bash
bin/rails generate ruby_llm:install \
  chat:Conversation \
  message:ChatMessage \
  model:AIModel
```

## Generators

```bash
# Agent with prompt template
bin/rails generate ruby_llm:agent Support

# Tool with view partials
bin/rails generate ruby_llm:tool Weather

# Schema
bin/rails generate ruby_llm:schema Product
```

## Error Handling

```ruby
class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    
    begin
      @chat.add_message(role: :user, content: params[:content])
      ChatStreamJob.perform_later(@chat.id)
    rescue RubyLLM::Error => e
      Rails.logger.error "LLM Error: #{e.message}"
      flash.now[:alert] = "AI service unavailable"
    end
  end
end
```

## Cost Tracking

```ruby
# v1.15+: Built-in cost calculation — no manual token math needed
class Chat < ApplicationRecord
  acts_as_chat

  after_ask :track_cost

  private

  def track_cost(response)
    # response.cost.total returns nil for unknown pricing rather than a bad estimate
    return unless response.cost.total

    Rails.cache.increment("cost:#{user_id}:#{Date.today}", response.cost.total)
  end
end
```

## Best Practices

### Always Use Background Jobs

```ruby
# Good - Non-blocking
ChatStreamJob.perform_later(chat_id)

# Bad - Blocks request
chat.complete { |chunk| ... }
```

### Security

```ruby
class SafeTool < RubyLLM::Tool
  param :input, desc: "User input"

  def execute(input:)
    raise ArgumentError if input.length > 1000
    # NEVER use: eval, system, exec, `
  end
end
```

## See Also

- **Main skill**: [rubyllm](../SKILL.md)
- **Agents**: [agents](../agents/SKILL.md)
- **Streaming**: Part of this skill (Hotwire section)
