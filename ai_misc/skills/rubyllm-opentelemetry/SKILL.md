---
name: rubyllm/opentelemetry
version: 0.4.0
description: |
  OpenTelemetry tracing for RubyLLM. Use this skill when you need observability into LLM applications with support for Langfuse, Datadog, Honeycomb, Jaeger, Arize Phoenix, and any OpenTelemetry-compatible backend.
---

# OpenTelemetry RubyLLM Instrumentation v{{ page.version }}

**Observability for RubyLLM Applications**

Adds OpenTelemetry tracing to RubyLLM. Send traces to any compatible backend (Langfuse, Datadog, Honeycomb, Jaeger, Arize Phoenix).

**Gem Version:** 0.4.0
**GitHub:** https://github.com/thoughtbot/opentelemetry-instrumentation-ruby_llm

## Installation

```bash
gem 'opentelemetry-instrumentation-ruby_llm'
gem 'opentelemetry-sdk'
gem 'opentelemetry-exporter-otlp'
```

## Setup

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/ruby_llm'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyLLM'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: ENV['OTEL_EXPORTER_OTLP_ENDPOINT'],
        headers: ENV['OTEL_EXPORTER_OTLP_HEADERS']
      )
    )
  )

  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    'service.name' => 'my-llm-app',
    'service.version' => '1.0.0'
  )
end
```

## Backend Configurations

### Langfuse

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyLLM'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'https://cloud.langfuse.com/api/public/otel',
        headers: {
          'Authorization' => "Basic #{ENV['LANGFUSE_PUBLIC_KEY']}:#{ENV['LANGFUSE_SECRET_KEY']}"
        }
      )
    )
  )
end
```

### Datadog

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyLLM'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: ENV['DD_TRACE_OTLP_ENDPOINT'] || 'http://localhost:4318'
      )
    )
  )
end
```

### Honeycomb

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyLLM'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'https://api.honeycomb.io:4318',
        headers: {
          'x-honeycomb-team' => ENV['HONEYCOMB_API_KEY'],
          'x-honeycomb-dataset' => ENV['HONEYCOMB_DATASET']
        }
      )
    )
  )
end
```

### Jaeger (Local Development)

```ruby
require 'opentelemetry/exporter/jaeger'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyLLM'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::Exporter::Jaeger::Agent.new(host: 'localhost', port: 6831)
    )
  )
end
```

### Arize Phoenix

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyLLM'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'http://localhost:4318/v1/traces'
      )
    )
  )
end
```

## Traced Operations

### Chat Completions

Automatically traces `Chat#ask`.

**Span Attributes:**
- `gen_ai.system` — Provider (openai, anthropic, etc.)
- `gen_ai.request.model` — Requested model
- `gen_ai.response.model` — Actual model used
- `gen_ai.usage.input_tokens` — Input tokens
- `gen_ai.usage.output_tokens` — Output tokens
- `gen_ai.operation.name` — `chat`

### Tool Calls

**Span Attributes:**
- `gen_ai.tool.name` — Tool name
- `gen_ai.tool.description` — Tool description
- `tool.arguments` — Tool arguments (JSON)
- `tool.result` — Tool result

**Events:** `tool_call`, `tool_result`

### Embeddings

**Span Attributes:**
- `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `embedding.dimensions`

### Image Generation

**Span Attributes:**
- `gen_ai.system`, `gen_ai.request.model`, `gen_ai.request.prompt`, `image.size`

### Audio Transcription

**Span Attributes:**
- `gen_ai.system`, `gen_ai.request.model`, `audio.duration`, `audio.language`

## Custom Attributes

```ruby
RubyLLM::Instrumentation.with(user_id: current_user.id, feature: "chat") do
  RubyLLM.chat.ask("Hello")
end
```

## Sampling

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyLLM'

  c.sampler = OpenTelemetry::SDK::Trace::Samplers.parent_based(
    root: OpenTelemetry::SDK::Trace::Samplers.trace_id_ratio_based(0.1)
  )
end
```

## Rails Integration

```ruby
# config/initializers/opentelemetry.rb
Rails.application.reloader.to_prepare do
  OpenTelemetry::SDK.configure do |c|
    c.use 'OpenTelemetry::Instrumentation::RubyLLM'
    c.use_all  # Auto-instrument other gems

    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new
      )
    )
  end
end
```

## See Also

- **Main RubyLLM**: [rubyllm](../rubyllm/SKILL.md)
- **Instrumentation**: [rubyllm-instrumentation](../rubyllm-instrumentation/SKILL.md)
- **OpenTelemetry**: https://opentelemetry.io
- **Source**: https://github.com/thoughtbot/opentelemetry-instrumentation-ruby_llm
