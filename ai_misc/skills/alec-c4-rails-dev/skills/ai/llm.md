# LLM Integration Skills

> **Gems:** `ruby-openai`, `anthropic`, `langchainrb`
> **Goal:** Integrate Large Language Models securely and efficiently.

## 1. Client Setup
Always wrap API calls in a Service or Interaction to handle timeouts and errors.

```ruby
# app/services/ai/completion_service.rb
class Ai::CompletionService
  def client
    @client ||= OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  def call(prompt)
    response = client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )
    response.dig("choices", 0, "message", "content")
  end
end
```

## 2. Prompt Engineering
- **System Prompts:** Store them in `config/prompts` or specific YAML files, not hardcoded in classes.
- **Context:** Inject dynamic data efficiently (don't dump the whole DB).

## 3. Streaming (Hotwire)
For better UX, stream responses using Turbo Streams.

```ruby
# Controller
def create
  Ai::StreamJob.perform_later(prompt: params[:prompt], user_id: current_user.id)
end

# Job
class Ai::StreamJob < ApplicationJob
  def perform(prompt:, user_id:)
    OpenAI::Client.new.chat(
      parameters: { ..., stream: proc { |chunk| broadcast(chunk) } }
    )
  end
end
```
