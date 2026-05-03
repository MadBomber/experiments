---
name: rubyllm
version: 1.14.1
description: |
  One beautiful Ruby API for GPT, Claude, Gemini, and more. Use this skill when building AI-powered applications with RubyLLM - chatbots, AI agents, RAG applications, content generators, vision/audio analysis, embeddings, image generation, and Rails integration. Supports 15+ providers with a unified interface.
allowed-tools:
  - Bash(bundle *)
  - Bash(bin/rails *)
---

# RubyLLM v1.14.1

**One beautiful Ruby API for GPT, Claude, Gemini, and more.**

RubyLLM provides a unified interface for working with AI models across 15+ providers. Build chatbots, AI agents, RAG applications, and content generators with the same simple API.

**Gem Version:** 1.14.1

## Installation

### Ruby Project

```bash
bundle add ruby_llm
```

```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']
end
```

### Rails Integration

```bash
bundle add ruby_llm
bin/rails generate ruby_llm:install
bin/rails db:migrate
bin/rails ruby_llm:load_models

# Optional: Add chat UI
bin/rails generate ruby_llm:chat_ui
# Visit http://localhost:3000/chats
```

## Quick Start

```ruby
# Basic chat
chat = RubyLLM.chat
response = chat.ask "What is Ruby on Rails?"

# Stream responses
chat.ask "Write a story" do |chunk|
  print chunk.content
end

# With tools
class Weather < RubyLLM::Tool
  description "Get weather"
  param :city, desc: "City name"
  def execute(city:)
    "Sunny in #{city}"
  end
end

chat.with_tool(Weather).ask "Weather in Paris?"
```

## Core Features

| Feature | Skill Reference |
|---------|----------------|
| Chat | This skill (below) |
| Tools | [tools](tools/SKILL.md) |
| Agents | [agents](agents/SKILL.md) |
| Streaming | This skill (Streaming section) |
| Embeddings | [embeddings](embeddings/SKILL.md) |
| Image Generation | [image-generation](image-generation/SKILL.md) |
| Audio Transcription | [audio-transcription](audio-transcription/SKILL.md) |
| Moderation | [moderation](moderation/SKILL.md) |
| Extended Thinking | This skill (Extended Thinking section) |
| Rails Integration | [rails](rails/SKILL.md) |

## Ecosystem Gems

| Gem | Version | Skill Reference |
|-----|---------|----------------|
| ruby_llm-schema | 0.3.0 | [schema](schema/SKILL.md) |
| ruby_llm-mcp | 1.0.0 | [mcp](mcp/SKILL.md) |
| ruby_llm-instrumentation | 0.3.1 | [instrumentation](instrumentation/SKILL.md) |
| ruby_llm-monitoring | 0.3.2 | [monitoring](monitoring/SKILL.md) |
| ruby_llm-red_candle | 0.2.0 | [red_candle](red_candle/SKILL.md) |
| ruby_llm-tribunal | 0.1.1 | [tribunal](tribunal/SKILL.md) |
| opentelemetry-instrumentation-ruby_llm | 0.4.0 | [opentelemetry](opentelemetry/SKILL.md) |

## Chat API

```ruby
# Create chat
chat = RubyLLM.chat(model: 'gpt-5.4')

# Ask question
response = chat.ask "What is Ruby?"

# Continue conversation (remembers context)
chat.ask "Show me an example"

# Access messages
chat.messages.each do |msg|
  puts "[#{msg.role}] #{msg.content}"
end

# System instructions
chat.with_instructions "You are a Ruby expert. Be concise."
```

## Providers

RubyLLM supports 15+ providers through a unified API:

| Provider | Models | Vision | Tools | Audio |
|----------|--------|--------|-------|-------|
| OpenAI | GPT-4, GPT-4o, o1, o3 | ✅ | ✅ | ✅ |
| Anthropic | Claude 3/4 | ✅ | ✅ | ❌ |
| Google | Gemini 1.5/2.0/2.5/3.0 | ✅ | ✅ | ✅ |
| xAI | Grok-1/2/3 | ✅ | ✅ | ❌ |
| AWS Bedrock | Claude, Llama, Titan | ✅ | ✅ | ❌ |
| Ollama | Local models | ✅ | ✅ | ✅ |
| OpenRouter | 300+ models | ✅ | ✅ | ❌ |
| Perplexity | Search models | ❌ | ✅ | ❌ |
| Mistral | Mistral/Mixtral | ✅ | ✅ | ❌ |
| DeepSeek | DeepSeek-V3 | ❌ | ✅ | ❌ |
| VertexAI | Google Cloud | ✅ | ✅ | ✅ |
| GPUStack | Self-hosted | ✅ | ✅ | ❌ |
| Azure OpenAI | Enterprise OpenAI | ✅ | ✅ | ✅ |

### Provider Setup

```ruby
RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']
  config.xai_api_key = ENV['XAI_API_KEY']
  config.perplexity_api_key = ENV['PERPLEXITY_API_KEY']
  config.mistral_api_key = ENV['MISTRAL_API_KEY']
  config.deepseek_api_key = ENV['DEEPSEEK_API_KEY']
end
```

### Model Selection

```ruby
# By model ID
chat = RubyLLM.chat(model: 'claude-sonnet-4-6')

# By provider routing
chat = RubyLLM.chat(model: 'claude-sonnet-4-6', provider: 'bedrock')

# Model registry
RubyLLM.models.supporting(:vision)
RubyLLM.models.find('gpt-5.4')
```

### Prompt Caching (Anthropic)

```ruby
raw_block = RubyLLM::Content::Raw.new([
  { 
    type: 'text', 
    text: File.read('large_document.txt'),
    cache_control: { type: 'ephemeral' }
  }
])

chat.add_message(role: :system, content: raw_block)
response = chat.ask(raw_block)
puts "Cached tokens: #{response.cached_tokens}"
```

## Extended Thinking

Give models more computation budget for complex reasoning (o1, o3, Claude Opus).

**New in v1.10**

```ruby
# Enable with effort level
chat = RubyLLM.chat(model: 'claude-opus-4-5')
  .with_thinking(effort: :high)

response = chat.ask("Complex problem")

# Access thinking trace
puts response.thinking&.text
puts response.thinking&.signature
puts response.thinking_tokens
```

### Effort Levels

```ruby
chat.with_thinking(effort: :low)     # Fast, cheap
chat.with_thinking(effort: :medium)  # Balanced
chat.with_thinking(effort: :high)    # Slow, accurate
chat.with_thinking(effort: :none)    # Disable
chat.with_thinking(budget: 10_000)   # Token cap
```

### Streaming with Thinking

```ruby
chat.ask "Solve step by step" do |chunk|
  print chunk.thinking&.text  # Some providers stream thinking
  print chunk.content
end
```

## Streaming

```ruby
chat.ask "Write a story" do |chunk|
  print chunk.content
  $stdout.flush
end

# With events
chat = RubyLLM.chat
  .on_new_message { print "Assistant > " }
  .on_end_message { |msg| puts "\n✓ Done (#{msg.output_tokens} tokens)" }

chat.ask "Hello" do |chunk|
  print chunk.content
end
```

## Multi-Modal

```ruby
# Images
chat.ask "What's in this image?", with: "photo.jpg"

# PDFs
chat.ask "Summarize this", with: "report.pdf"

# Audio
chat.ask "Transcribe", with: "meeting.mp3"

# Multiple files
chat.ask "Analyze", with: ["image.jpg", "doc.pdf", "notes.txt"]
```

## Token Tracking

```ruby
response = chat.ask "Hello"

puts "Input: #{response.input_tokens}"
puts "Output: #{response.output_tokens}"
puts "Cached: #{response.cached_tokens}"
puts "Thinking: #{response.thinking_tokens}"

# Cost estimation
model = RubyLLM.models.find(response.model_id)
cost = (response.input_tokens * model.input_price_per_million / 1_000_000) +
       (response.output_tokens * model.output_price_per_million / 1_000_000)
```

## Error Handling

```ruby
begin
  response = chat.ask "Hello"
rescue RubyLLM::AuthenticationError
  # Invalid API key
rescue RubyLLM::RateLimitError => e
  sleep e.retry_after
  retry
rescue RubyLLM::TimeoutError
  # Request timeout
rescue RubyLLM::ContextLengthExceededError
  # Reduce prompt size
rescue RubyLLM::Error => e
  # Generic API error
end
```

### Error Types

| Error | HTTP | Description |
|-------|------|-------------|
| `BadRequestError` | 400 | Invalid parameters |
| `UnauthorizedError` | 401 | Invalid API key |
| `PaymentRequiredError` | 402 | Billing issue |
| `RateLimitError` | 429 | Rate limit exceeded |
| `ContextLengthExceededError` | - | Token limit |
| `ServerError` | 500 | Provider error |
| `ServiceUnavailableError` | 502/503/504 | Service down |

## Debugging

```bash
export RUBYLLM_DEBUG=true
```

Shows full request/response details in logs.

## Best Practices

### Tool Security

```ruby
class SafeTool < RubyLLM::Tool
  param :input, desc: "User input"

  def execute(input:)
    raise ArgumentError if input.length > 1000
    # NEVER use: eval, system, exec, `
  end
end
```

### Cost Control

```ruby
simple_chat = RubyLLM.chat(model: 'gpt-5-nano')  # Cheap
complex_chat = RubyLLM.chat(model: 'claude-sonnet-4-6')  # Capable
```

### Context Management

```ruby
if chat.messages.sum { |m| m.input_tokens + m.output_tokens } > 100_000
  summary = summarize(chat.messages.first(40))
  chat.reset_messages!
  chat.add_message(role: :system, content: summary)
end
```

## Resources

- **Official Docs**: https://rubyllm.com
- **GitHub**: https://github.com/crmne/ruby_llm
