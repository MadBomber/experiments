---
name: rubyllm/instrumentation
version: 0.3.1
description: |
  ActiveSupport::Notifications instrumentation for RubyLLM. Use this skill when building custom monitoring, logging, or analytics for RubyLLM usage. Publishes events for chat completions, tools, embeddings, images, moderation, and transcription.
---

# RubyLLM::Instrumentation v0.3.1

**Rails instrumentation for RubyLLM**

Uses ActiveSupport::Notifications to publish events for all RubyLLM operations. Build custom monitoring, logging, or analytics.

**Gem Version:** 0.3.1  
**GitHub:** https://github.com/sinaptia/ruby_llm-instrumentation

## Installation

```bash
gem 'ruby_llm-instrumentation'
```

Auto-loads when both `ruby_llm` and `ruby_llm-instrumentation` are in your Gemfile.

## Subscribing to Events

### Subscribe to All LLM Events

```ruby
ActiveSupport::Notifications.subscribe(/ruby_llm/) do |name, start, finish, id, payload|
  duration = ((finish - start) * 1000).round(2)
  
  Rails.logger.info "LLM Call: #{payload[:provider]}/#{payload[:model]}"
  Rails.logger.info "Duration: #{duration}ms"
  Rails.logger.info "Input tokens: #{payload[:input_tokens]}"
  Rails.logger.info "Output tokens: #{payload[:output_tokens]}"
  Rails.logger.info "Metadata: #{payload[:metadata]}" if payload[:metadata]
end
```

### Subscribe to Specific Events

```ruby
ActiveSupport::Notifications.subscribe('complete_chat.ruby_llm') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  
  # Track in Datadog
  Datadog::Tracing.trace('ruby_llm.chat') do |span|
    span.set_tag('provider', event.payload[:provider])
    span.set_tag('model', event.payload[:model])
    span.set_tag('input_tokens', event.payload[:input_tokens])
    span.set_tag('output_tokens', event.payload[:output_tokens])
    span.set_tag('duration', event.duration)
  end
end
```

## Available Events

### complete_chat.ruby_llm

Triggered when `Chat#ask` is called.

| Key | Value |
|-----|-------|
| provider | Provider slug |
| model | Model ID |
| streaming | Whether streaming was used |
| chat | RubyLLM::Chat object |
| response | RubyLLM::Message object |
| input_tokens | Input tokens consumed |
| output_tokens | Output tokens consumed |
| cached_tokens | Cache reads (if supported) |
| cache_creation_tokens | Cache writes (if supported) |
| metadata | Custom metadata hash |

### execute_tool.ruby_llm

Triggered when a tool is executed.

| Key | Value |
|-----|-------|
| tool_name | Name of the tool |
| tool_arguments | Tool arguments hash |
| tool_result | Tool result |
| duration | Execution time |

### embed_text.ruby_llm

Triggered when `Embedding.embed` is called.

| Key | Value |
|-----|-------|
| provider | Provider slug |
| model | Model ID |
| texts | Array of texts |
| dimensions | Vector dimensions |
| input_tokens | Input tokens |

### paint_image.ruby_llm

Triggered when `Image.paint` is called.

| Key | Value |
|-----|-------|
| provider | Provider slug |
| model | Model ID |
| prompt | Image prompt |
| size | Image size |

### moderate_text.ruby_llm

Triggered when `Moderation.moderate` is called.

| Key | Value |
|-----|-------|
| provider | Provider slug |
| model | Model ID |
| flagged | Whether content was flagged |
| categories | Category scores |

### transcribe_audio.ruby_llm

Triggered when `Transcription.transcribe` is called.

| Key | Value |
|-----|-------|
| provider | Provider slug |
| model | Model ID |
| duration | Audio duration |
| language | Detected language |

## Custom Metadata

### Block Form

```ruby
RubyLLM::Instrumentation.with(user_id: current_user.id, feature: "chat_assistant") do
  RubyLLM.chat.ask("Hello")
end
```

### One-Liners

```ruby
RubyLLM::Instrumentation.with(feature: "search") { RubyLLM.embed("text") }
```

### Around Action (Controllers)

```ruby
class ApplicationController < ActionController::Base
  around_action :instrument_llm_calls

  private

  def instrument_llm_calls
    RubyLLM::Instrumentation.with(
      user_id: current_user&.id,
      request_id: request.uuid
    ) do
      yield
    end
  end
end
```

### Nested Blocks

Nested blocks merge metadata:

```ruby
RubyLLM::Instrumentation.with(user_id: 123) do
  RubyLLM::Instrumentation.with(feature: "chat") do
    RubyLLM.chat.ask("Hello")
    # metadata: { user_id: 123, feature: "chat" }
  end
end
```

## Analytics Example

```ruby
# app/models/llm_usage.rb
class LlmUsage
  def self.track_event(name, start, finish, id, payload)
    create!(
      provider: payload[:provider],
      model: payload[:model],
      input_tokens: payload[:input_tokens],
      output_tokens: payload[:output_tokens],
      duration_ms: ((finish - start) * 1000).round(2),
      metadata: payload[:metadata]
    )
  end
end

# config/initializers/llm_analytics.rb
ActiveSupport::Notifications.subscribe('complete_chat.ruby_llm') do |*args|
  LlmUsage.track_event(*args)
end
```

## Cost Tracking

```ruby
class LlmCostTracker
  COSTS = {
    'gpt-5.4' => { input: 2.50, output: 10.00 },
    'claude-sonnet-4-6' => { input: 3.00, output: 15.00 }
  }.freeze

  def self.track(*args)
    event = ActiveSupport::Notifications::Event.new(*args)
    model = event.payload[:model]
    pricing = COSTS[model]
    
    if pricing
      cost = (event.payload[:input_tokens] * pricing[:input] / 1_000_000) +
             (event.payload[:output_tokens] * pricing[:output] / 1_000_000)
      
      Rails.cache.increment("cost:#{Date.today}", cost)
    end
  end
end

ActiveSupport::Notifications.subscribe('complete_chat.ruby_llm') do |*args|
  LlmCostTracker.track(*args)
end
```

## Alerting

```ruby
ActiveSupport::Notifications.subscribe('complete_chat.ruby_llm') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  
  # Alert on high error rates
  if event.payload[:error]
    SlackNotifier.send("LLM Error: #{event.payload[:error]}")
  end
  
  # Alert on high latency
  if event.duration > 30 # seconds
    SlackNotifier.send("Slow LLM response: #{event.duration}s")
  end
  
  # Alert on high costs
  if event.payload[:output_tokens] > 10_000
    SlackNotifier.send("Large response: #{event.payload[:output_tokens]} tokens")
  end
end
```

## See Also

- **Main RubyLLM**: [rubyllm](../SKILL.md)
- **Monitoring**: [rubyllm/monitoring](../monitoring/SKILL.md)
