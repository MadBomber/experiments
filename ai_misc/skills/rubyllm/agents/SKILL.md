---
name: rubyllm-agents
description: |
  Define reusable AI assistants with RubyLLM::Agent. Use this skill when creating class-based agents with persistent configuration, runtime context, prompt management, Rails-backed agents, and agentic workflows.
allowed-tools:
  - Bash(bundle *)
  - Bash(bin/rails *)
---

# RubyLLM Agents

Define reusable AI assistants with class-based configuration, runtime context, and prompt conventions.

## What Are Agents?

Agents are named, reusable wrappers around chat configuration:

```ruby
# Instead of this everywhere:
chat = RubyLLM.chat(model: "gpt-5-nano")
chat.with_instructions("You are a support assistant.")
chat.with_tools(SearchDocs, LookupAccount)

# Define once:
class SupportAgent < RubyLLM::Agent
  model "gpt-5-nano"
  instructions "You are a support assistant."
  tools SearchDocs, LookupAccount
end

# Use anywhere:
response = SupportAgent.new.ask "How do I reset my password?"
```

## Defining an Agent

```ruby
class WorkAssistant < RubyLLM::Agent
  model "gpt-5-nano"
  instructions "You are a helpful assistant."
  tools SearchDocs, LookupAccount
  temperature 0.2
  params max_output_tokens: 256
end
```

### Supported Macros

- `model` - Model ID or alias
- `tools` - Tools to use
- `instructions` - System prompt
- `temperature` - Response creativity (0.0-1.0)
- `thinking` - Extended thinking config
- `params` - Provider-specific parameters
- `headers` - Custom HTTP headers
- `schema` - Output schema (class, hash, or DSL block)
- `context` - Custom API context
- `chat_model` - Rails ActiveRecord model
- `inputs` - Declared runtime inputs

### Inline Schema DSL

```ruby
class CriticAgent < RubyLLM::Agent
  schema do
    string :verdict, enum: ["pass", "revise"]
    string :feedback
  end
end
```

## Runtime Context & Inputs

```ruby
class WorkAssistant < RubyLLM::Agent
  chat_model Chat
  inputs :workspace

  instructions { "You are helping #{workspace.name}" }
  
  tools do
    [TodoTool.new(chat: chat)]
  end
end

# Usage
agent = WorkAssistant.new(workspace: current_workspace)
agent.ask "Help me"
```

> **Important**: Values depending on runtime `chat` must be lazy (blocks/lambdas).

## Prompt Management

### Auto-Load from File

```ruby
class WorkAssistant < RubyLLM::Agent
  chat_model Chat
  instructions  # Loads from app/prompts/work_assistant/instructions.txt.erb
end
```

### With Locals

```ruby
class WorkAssistant < RubyLLM::Agent
  instructions display_name: -> { chat.user.display_name_or_email }
end
```

### Naming Conventions

- `WorkAssistant` → `app/prompts/work_assistant/...`
- `Admin::SupportAgent` → `app/prompts/admin/support_agent/...`

## Using Agents

### Plain Ruby

```ruby
# Get configured chat
chat = WorkAssistant.chat
response = chat.ask("Hello")

# Or instantiate
agent = WorkAssistant.new
response = agent.ask("Hello")

# Cost tracking (v1.15+) — accumulates across all asks on this instance
puts agent.cost.total
```

### Rails-Backed

```ruby
class WorkAssistant < RubyLLM::Agent
  chat_model Chat
  model "gpt-5-nano"
  instructions "You are helpful"
  tools SearchDocs
end

# Create persisted chat
chat = WorkAssistant.create!(user: current_user)

# Find existing (applies config at runtime)
chat = WorkAssistant.find(params[:id])

# Sync instructions explicitly
WorkAssistant.sync_instructions!(chat)
```

## When to Use Agents

### Use `RubyLLM.chat` for One-Off

```ruby
chat = RubyLLM.chat(model: "gpt-5-nano")
chat.with_instructions "Explain this clearly."
```

### Use Agents for Reusable Behavior

```ruby
class CodeReviewAgent < RubyLLM::Agent
  model "claude-sonnet-4-6"
  instructions "You are a senior engineer. Review for correctness, performance, security."
  tools Linter, SecurityScanner
end

CodeReviewAgent.new.ask "Review this PR"
```

## Examples

### Customer Support Agent

```ruby
class SupportAgent < RubyLLM::Agent
  chat_model Chat
  model "gpt-5-nano"
  temperature 0.3
  
  instructions do
    current_date_time: -> { Time.current.strftime("%B %d, %Y") },
    display_name: -> { chat.user.display_name }
  end
  
  tools SearchKnowledgeBase, CreateTicket
end
```

### Code Review Agent

```ruby
class CodeReviewAgent < RubyLLM::Agent
  model "claude-sonnet-4-6"
  instructions "Review for correctness, performance, security, readability."
  
  schema do
    object :review do
      string :summary
      array :issues do
        object do
          string :severity, enum: ["critical", "major", "minor"]
          string :location
          string :suggestion
        end
      end
      integer :score, description: "1-10"
    end
  end
end
```

## Best Practices

### Keep Agents Focused

```ruby
# Good - Single responsibility
class SupportAgent < RubyLLM::Agent
  instructions "You handle customer support questions only."
end
```

### Use Prompt Files for Long Instructions

```ruby
class SupportAgent < RubyLLM::Agent
  instructions  # Loads from app/prompts/support_agent/instructions.txt.erb
end
```

### Lazy Evaluation

```ruby
# Good - Lazy
instructions { "Helping #{workspace.name}" }

# Bad - Eager (workspace not available at class load)
instructions "Helping #{workspace.name}"  # Error!
```

## See Also

- **Main skill**: [rubyllm](../SKILL.md)
- **Tools**: [tools](../tools/SKILL.md)
- **Rails**: [rails](../rails/SKILL.md)
