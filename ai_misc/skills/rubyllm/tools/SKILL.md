---
name: rubyllm-tools
description: |
  Function calling for RubyLLM. Use this skill when creating tools that let AI call your Ruby code, declaring parameters with the params DSL, using tools in chat, monitoring tool calls with callbacks, handling tool security, and implementing advanced patterns like halt and provider-specific parameters.
allowed-tools:
  - Bash(bundle *)
  - Bash(bin/rails *)
---

# RubyLLM Tools

Let AI call your Ruby methods. Connect to databases, APIs, or any external system.

## Creating a Tool

```ruby
class Weather < RubyLLM::Tool
  description "Get current weather for a location"
  
  params do
    string :latitude, description: "Latitude coordinate"
    string :longitude, description: "Longitude coordinate"
  end

  def execute(latitude:, longitude:)
    url = "https://api.open-meteo.com/v1/forecast?latitude=#{latitude}&longitude=#{longitude}&current=temperature_2m,wind_speed_10m"
    response = Faraday.get(url)
    JSON.parse(response.body).to_json
  end
end
```

## Parameter Declaration

### Method Signature Inference (v1.15+)

Required and optional keyword arguments are automatically inferred as tool parameters — no `params` block needed:

```ruby
class Weather < RubyLLM::Tool
  description "Get weather for a location"

  def execute(latitude:, longitude:, units: "celsius")
    # latitude, longitude → required params
    # units → optional param (has default)
  end
end
```

### params DSL (v1.9+)

```ruby
class Scheduler < RubyLLM::Tool
  description "Book a meeting"

  params do
    object :window, description: "Time window" do
      string :start, description: "ISO8601 start"
      string :finish, description: "ISO8601 end"
    end

    array :participants, of: :string, description: "Email addresses"
  end

  def execute(window:, participants:)
    # Implementation
  end
end
```

### param Helper (Simple Tools)

```ruby
class Distance < RubyLLM::Tool
  description "Calculate distance between cities"
  param :origin, desc: "Origin city name"
  param :destination, desc: "Destination city name"

  def execute(origin:, destination:)
    # Implementation
  end
end
```

## Using Tools

```ruby
# Single tool
chat = RubyLLM.chat.with_tool(Weather)
response = chat.ask "Weather in Berlin? (52.52, 13.40)"

# Multiple tools
chat.with_tools(Weather, Calculator, SearchDB)

# Tool choice
chat.with_tools(Weather, choice: :auto)     # AI decides
chat.with_tools(Weather, choice: :required) # Must call tool
chat.with_tools(Weather, choice: :none)     # Disable tools

# Control parallel calls
chat.with_tools(Weather, calls: :many)  # Multiple calls (default)
chat.with_tools(Weather, calls: :one)   # One call per response
```

## Tool Monitoring

```ruby
# v1.15+ callbacks
chat = RubyLLM.chat
  .with_tool(Weather)
  .before_tool_call { |tc| puts "Calling: #{tc.name} args=#{tc.arguments}" }
  .after_tool_result { |result| puts "Result: #{result}" }

chat.ask "Weather?"
```

> **Deprecated (v1.15, removed in v2.0):** `on_tool_call` and `on_tool_result`.
> Replace with `before_tool_call` and `after_tool_result`.

## Rich Content from Tools

```ruby
class AnalyzeTool < RubyLLM::Tool
  description "Analyze and return with visualization"
  param :data, desc: "Data to analyze"

  def execute(data:)
    chart_path = generate_chart(data)
    
    # Return with attachment AI can see
    RubyLLM::Content.new("Analysis complete", [chart_path])
  end
end
```

## Halt Tool Continuation

Skip AI commentary after tool execution:

```ruby
class SaveFileTool < RubyLLM::Tool
  description "Save content to file"
  param :path, desc: "File path"
  param :content, desc: "Content"

  def execute(path:, content:)
    File.write(path, content)
    halt "Saved to #{path}"  # Return directly, no AI commentary
  end
end
```

## Provider-Specific Parameters (v1.9+)

```ruby
class TodoTool < RubyLLM::Tool
  description "Add task to TODO list"
  params do
    string :title
  end

  with_params cache_control: { type: "ephemeral" }  # Anthropic cache

  def execute(title:)
    Todo.create!(title:)
  end
end
```

## Security

> ⚠️ **Treat tool arguments as untrusted user input**

```ruby
class SafeTool < RubyLLM::Tool
  param :input, desc: "User input"

  def execute(input:)
    # Validate
    raise ArgumentError if input.length > 1000
    raise ArgumentError if input.match?(/[<>;]/)
    
    # NEVER use: eval, system, exec, `
  end
end
```

## Error Handling

```ruby
class WeatherTool < RubyLLM::Tool
  def execute(city:)
    return { error: "City too short" } if city.length < 3
    
    Faraday.get("https://api.weather.com/#{city}")
  rescue Faraday::ConnectionFailed
    { error: "Weather service unavailable" }
  end
end
```

### Error Strategy

- **Recoverable** (bad params, API down): Return `{ error: "message" }`
- **Unrecoverable** (missing config, DB down): Raise exception

## See Also

- **Main skill**: [rubyllm](../SKILL.md)
- **Agents**: [agents](../agents/SKILL.md)
