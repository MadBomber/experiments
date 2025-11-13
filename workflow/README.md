# SimpleFlow

A lightweight, modular Ruby framework for building composable data processing pipelines with middleware support and flow control.

## Overview

SimpleFlow provides a clean and flexible architecture for orchestrating multi-step workflows. It emphasizes:

- **Immutability**: Results are immutable, promoting safer concurrent operations
- **Composability**: Steps and middleware can be easily combined and reused
- **Flow Control**: Built-in mechanisms to halt or continue execution based on step outcomes
- **Middleware Support**: Cross-cutting concerns (logging, instrumentation, etc.) via decorator pattern
- **Simplicity**: Minimal API surface with powerful capabilities

## Core Components

### Result (`result.rb:13`)

An immutable value object representing the outcome of a workflow step.

```ruby
result = SimpleFlow::Result.new(initial_value)
  .with_context(:user_id, 123)
  .with_error(:validation, "Invalid input")
```

**Key Methods:**
- `continue(new_value)` - Proceeds to next step with updated value
- `halt(new_value = nil)` - Stops pipeline execution
- `with_context(key, value)` - Adds contextual metadata
- `with_error(key, message)` - Accumulates error messages
- `continue?` - Checks if pipeline should proceed

### Pipeline (`pipeline.rb:19`)

Orchestrates step execution with middleware integration.

```ruby
pipeline = SimpleFlow::Pipeline.new do
  use_middleware SimpleFlow::MiddleWare::Logging
  use_middleware SimpleFlow::MiddleWare::Instrumentation, api_key: 'xyz'

  step ->(result) { result.continue(result.value + 10) }
  step ->(result) { result.continue(result.value * 2) }
end

initial = SimpleFlow::Result.new(5)
final = pipeline.call(initial)  # => Result with value 30
```

**Features:**
- DSL for pipeline configuration
- Automatic middleware application to all steps
- Short-circuit evaluation when `result.continue?` is false
- Steps are any callable object (`#call`)

### Middleware (`middleware.rb`)

Wraps steps with cross-cutting functionality using the decorator pattern.

**Built-in Middleware:**

- **Logging** (`middleware.rb:3`) - Logs before/after step execution
- **Instrumentation** (`middleware.rb:22`) - Measures step duration

**Custom Middleware:**

```ruby
class AuthMiddleware
  def initialize(callable, required_role:)
    @callable = callable
    @required_role = required_role
  end

  def call(result)
    return result.halt.with_error(:auth, "Unauthorized") unless authorized?(result)
    @callable.call(result)
  end

  private

  def authorized?(result)
    result.context[:user_role] == @required_role
  end
end

# Usage
pipeline = SimpleFlow::Pipeline.new do
  use_middleware AuthMiddleware, required_role: :admin
  step ->(result) { result.continue("Sensitive operation") }
end
```

### StepTracker (`step_tracker.rb:43`)

A `SimpleDelegator` that enriches halted results with context about where execution stopped.

```ruby
tracked_step = SimpleFlow::StepTracker.new(my_step)
result = tracked_step.call(input)
result.context[:halted_step]  # => my_step (if halted)
```

## Usage Examples

### Basic Pipeline

```ruby
require_relative 'simple_flow'

pipeline = SimpleFlow::Pipeline.new do
  step ->(result) {
    result.continue(result.value.strip.downcase)
  }
  step ->(result) {
    result.continue("Hello, #{result.value}!")
  }
end

result = pipeline.call(SimpleFlow::Result.new("  WORLD  "))
puts result.value  # => "Hello, world!"
```

### Error Handling

```ruby
validate_age = ->(result) {
  age = result.value
  if age < 0
    result.halt.with_error(:validation, "Age cannot be negative")
  elsif age < 18
    result.halt.with_error(:validation, "Must be 18 or older")
  else
    result.continue(age)
  end
}

check_eligibility = ->(result) {
  result.continue("Eligible at age #{result.value}")
}

pipeline = SimpleFlow::Pipeline.new do
  step validate_age
  step check_eligibility  # Won't execute if validation fails
end

result = pipeline.call(SimpleFlow::Result.new(15))
puts result.continue?  # => false
puts result.errors     # => {:validation=>["Must be 18 or older"]}
```

### Context Propagation

```ruby
pipeline = SimpleFlow::Pipeline.new do
  step ->(result) {
    result
      .with_context(:started_at, Time.now)
      .continue(result.value)
  }

  step ->(result) {
    result
      .with_context(:processed_by, "step_2")
      .continue(result.value.upcase)
  }
end

result = pipeline.call(SimpleFlow::Result.new("data"))
puts result.value    # => "DATA"
puts result.context  # => {:started_at=>..., :processed_by=>"step_2"}
```

### Conditional Flow

```ruby
pipeline = SimpleFlow::Pipeline.new do
  step ->(result) {
    if result.value > 100
      result.halt(result.value).with_error(:limit, "Value exceeds maximum")
    else
      result.continue(result.value)
    end
  }

  step ->(result) {
    result.continue(result.value * 2)  # Only runs if value <= 100
  }
end
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Pipeline                      │
│  ┌───────────────────────────────────────────┐  │
│  │ Middleware Stack (applied in reverse)    │  │
│  │  - Instrumentation                       │  │
│  │  - Logging                               │  │
│  │  - Custom...                             │  │
│  └───────────────────────────────────────────┘  │
│                      ↓                          │
│  ┌───────────────────────────────────────────┐  │
│  │ Steps (executed sequentially)            │  │
│  │  1. Step → Result                        │  │
│  │  2. Step → Result (if continue?)         │  │
│  │  3. Step → Result (if continue?)         │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                       ↓
              ┌────────────────┐
              │ Final Result   │
              │  - value       │
              │  - context     │
              │  - errors      │
              └────────────────┘
```

## Design Patterns

1. **Pipeline Pattern**: Sequential processing with short-circuit capability
2. **Decorator Pattern**: Middleware wraps steps to add behavior
3. **Immutable Value Object**: Results are never modified, only copied
4. **Builder Pattern**: DSL for pipeline configuration
5. **Chain of Responsibility**: Each step can handle or pass along the result

## Testing

Run the test suite:

```bash
ruby workflow/simple_flow_test.rb
```

Key test scenarios in `simple_flow_test.rb:5`:
- Pipeline execution with multiple steps
- Middleware integration
- Context and error handling
- Halt execution behavior

## Dependencies

- Ruby 2.7+ (uses `SimpleDelegator`)
- Standard library only (no external gems)

## Files

- `simple_flow.rb:1` - Main module file with overview
- `result.rb:13` - Immutable result object
- `pipeline.rb:19` - Pipeline orchestration
- `middleware.rb:2` - Middleware implementations
- `step_tracker.rb:43` - Step tracking decorator
- `simple_flow_test.rb:5` - Test suite

## License

Experimental code - use at your own discretion.
