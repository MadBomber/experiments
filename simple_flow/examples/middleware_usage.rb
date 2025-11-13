#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/simple_flow'

puts "=" * 60
puts "SimpleFlow - Middleware Usage Example"
puts "=" * 60

# Example 1: Logging Middleware
puts "\n1. Logging Middleware"
puts "-" * 60

pipeline_with_logging = SimpleFlow::Pipeline.new do
  use_middleware SimpleFlow::Middleware::Logging, level: :info

  step :parse_input, ->(result) {
    result.continue(result.value.strip.upcase)
  }

  step :validate_input, ->(result) {
    if result.value.length < 3
      result.halt.with_error(:validation, "Too short", severity: :error)
    else
      result.continue(result.value)
    end
  }

  step :process, ->(result) {
    result.continue("Processed: #{result.value}")
  }
end

result1 = pipeline_with_logging.call(SimpleFlow::Result.new("  hello  "))
puts "\nFinal: #{result1.value}"

# Example 2: Instrumentation Middleware
puts "\n\n2. Instrumentation Middleware"
puts "-" * 60

pipeline_with_instrumentation = SimpleFlow::Pipeline.new do
  use_middleware SimpleFlow::Middleware::Instrumentation, api_key: "my-api-key"

  step :slow_step, ->(result) {
    sleep 0.1
    result.continue(result.value * 2)
  }

  step :fast_step, ->(result) {
    result.continue(result.value + 10)
  }
end

result2 = pipeline_with_instrumentation.call(SimpleFlow::Result.new(5))
puts "\nResult: #{result2.value}"
puts "Slow step duration: #{result2.context[:slow_step_duration].round(3)}s"
puts "Fast step duration: #{result2.context[:fast_step_duration].round(6)}s"

# Example 3: Retry Middleware
puts "\n\n3. Retry Middleware"
puts "-" * 60

attempt_count = 0

pipeline_with_retry = SimpleFlow::Pipeline.new do
  use_middleware SimpleFlow::Middleware::Retry,
                  max_attempts: 4,
                  backoff: 0.5,
                  on_retry: ->(result, attempt, error) {
                    puts "  Retry attempt #{attempt}: #{error.message}"
                  }

  step :flaky_operation, ->(result) {
    attempt_count += 1
    puts "  Executing attempt ##{attempt_count}"

    if attempt_count < 3
      raise StandardError, "Temporary failure"
    end

    result.continue("Success after #{attempt_count} attempts")
  }
end

result3 = pipeline_with_retry.call(SimpleFlow::Result.new(nil))
puts "\nResult: #{result3.value}"

# Example 4: Multiple Middlewares (Stacking)
puts "\n\n4. Stacked Middlewares"
puts "-" * 60

attempt_count2 = 0

stacked_pipeline = SimpleFlow::Pipeline.new do
  # Middleware is applied in reverse order (like Russian dolls)
  # So Logging wraps Instrumentation which wraps Retry which wraps the step
  use_middleware SimpleFlow::Middleware::Logging, level: :info
  use_middleware SimpleFlow::Middleware::Instrumentation, api_key: "stack-test"
  use_middleware SimpleFlow::Middleware::Retry, max_attempts: 2, backoff: 0.1

  step :reliable_step, ->(result) {
    result.continue(result.value.upcase)
  }
end

puts "\nProcessing with all middlewares:"
result4 = stacked_pipeline.call(SimpleFlow::Result.new("hello"))
puts "\nResult: #{result4.value}"
puts "Duration tracked: #{result4.context.key?(:reliable_step_duration)}"

# Example 5: Custom Middleware
puts "\n\n5. Custom Middleware"
puts "-" * 60

# Define a custom middleware that adds a timestamp
class TimestampMiddleware
  def initialize(callable, prefix: "timestamp")
    @callable = callable
    @prefix = prefix
  end

  def call(result)
    step_name = result.context[:current_step] || :unknown

    # Add "before" timestamp
    result = result.with_context(:"#{@prefix}_#{step_name}_start", Time.now)

    # Call the wrapped step
    result = @callable.call(result)

    # Add "after" timestamp
    result = result.with_context(:"#{@prefix}_#{step_name}_end", Time.now)

    result
  end
end

custom_pipeline = SimpleFlow::Pipeline.new do
  use_middleware TimestampMiddleware, prefix: "ts"

  step :step_one, ->(result) {
    sleep 0.05
    result.continue(result.value + 1)
  }

  step :step_two, ->(result) {
    sleep 0.03
    result.continue(result.value * 2)
  }
end

result5 = custom_pipeline.call(SimpleFlow::Result.new(10))
puts "Result: #{result5.value}"
puts "\nTimestamps:"
puts "  Step 1 start: #{result5.context[:ts_step_one_start]}"
puts "  Step 1 end:   #{result5.context[:ts_step_one_end]}"
puts "  Step 2 start: #{result5.context[:ts_step_two_start]}"
puts "  Step 2 end:   #{result5.context[:ts_step_two_end]}"

# Example 6: Conditional Middleware Application
puts "\n\n6. Proc-based Middleware (Lambda)"
puts "-" * 60

# You can also use a Proc/lambda as middleware
validation_middleware = ->(callable) {
  ->(result) {
    puts "  [Validation MW] Checking before execution..."

    # Execute the step
    result = callable.call(result)

    # Check after execution
    if result.value.is_a?(String) && result.value.empty?
      result.with_error(:validation, "Empty result detected", severity: :warning)
    else
      result
    end
  }
}

proc_pipeline = SimpleFlow::Pipeline.new do
  use_middleware validation_middleware

  step :generate, ->(result) {
    result.continue("Generated: #{result.value}")
  }
end

result6 = proc_pipeline.call(SimpleFlow::Result.new("data"))
puts "Result: #{result6.value}"
puts "Warnings: #{result6.warnings.size}"

puts "\n" + "=" * 60
puts "Middleware Examples completed!"
puts "=" * 60
