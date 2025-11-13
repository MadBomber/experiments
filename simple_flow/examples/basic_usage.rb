#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/simple_flow'

puts "=" * 60
puts "SimpleFlow - Basic Usage Example"
puts "=" * 60

# Example 1: Simple Sequential Pipeline
puts "\n1. Simple Sequential Pipeline"
puts "-" * 60

pipeline = SimpleFlow::Pipeline.new(name: :data_processor) do
  step :parse, ->(result) {
    puts "  Parsing: #{result.value}"
    result.continue(result.value.strip.upcase)
  }

  step :validate, ->(result) {
    puts "  Validating: #{result.value}"
    if result.value.empty?
      result.halt.with_error(:validation, "Input cannot be empty", severity: :error)
    else
      result.continue(result.value)
    end
  }

  step :process, ->(result) {
    puts "  Processing: #{result.value}"
    result.continue("Processed: #{result.value}")
  }
end

result = pipeline.call(SimpleFlow::Result.new("  hello world  "))
puts "\nResult: #{result.value}"
puts "Success: #{result.success?}"

# Example 2: Pipeline with Halt
puts "\n2. Pipeline with Halt on Validation Error"
puts "-" * 60

result2 = pipeline.call(SimpleFlow::Result.new("   "))
puts "Result: #{result2.value}"
puts "Success: #{result2.success?}"
puts "Errors: #{result2.all_errors.map(&:message)}"

# Example 3: Conditional Steps
puts "\n3. Conditional Steps"
puts "-" * 60

conditional_pipeline = SimpleFlow::Pipeline.new do
  step :check_input, ->(result) {
    puts "  Input: #{result.value}"
    result.continue(result.value)
  }

  step_if :apply_discount,
          ->(result) { result.value > 100 },
          ->(result) {
            puts "  Applying 10% discount"
            result.continue(result.value * 0.9)
          }

  step :format_output, ->(result) {
    puts "  Final amount: $#{result.value}"
    result.continue("$#{result.value.round(2)}")
  }
end

puts "\nSmall amount (no discount):"
result3 = conditional_pipeline.call(SimpleFlow::Result.new(50))
puts "Result: #{result3.value}"

puts "\nLarge amount (with discount):"
result4 = conditional_pipeline.call(SimpleFlow::Result.new(150))
puts "Result: #{result4.value}"

# Example 4: Pipeline Composition
puts "\n4. Pipeline Composition"
puts "-" * 60

validation_pipeline = SimpleFlow::Pipeline.new(name: :validator) do
  step :validate_format, ->(result) {
    puts "  Validating format..."
    result.continue(result.value)
  }

  step :validate_length, ->(result) {
    puts "  Validating length..."
    if result.value.length < 5
      result.halt.with_error(:validation, "Too short")
    else
      result.continue(result.value)
    end
  }
end

processing_pipeline = SimpleFlow::Pipeline.new(name: :processor) do
  step :transform, ->(result) {
    puts "  Transforming..."
    result.continue(result.value.upcase)
  }

  step :enrich, ->(result) {
    puts "  Enriching..."
    result.continue("ENRICHED: #{result.value}")
  }
end

# Compose pipelines
full_pipeline = validation_pipeline >> processing_pipeline

result5 = full_pipeline.call(SimpleFlow::Result.new("hello"))
puts "\nResult: #{result5.value}"
puts "Success: #{result5.success?}"

# Example 5: Context and Error Tracking
puts "\n5. Context and Error Tracking"
puts "-" * 60

tracking_pipeline = SimpleFlow::Pipeline.new do
  step :add_metadata, ->(result) {
    result
      .with_context(:timestamp, Time.now)
      .with_context(:user_id, 12345)
      .continue(result.value)
  }

  step :process_with_warnings, ->(result) {
    result
      .with_error(:warning, "This is a warning", severity: :warning)
      .continue(result.value.upcase)
  }

  step :final_check, ->(result) {
    puts "  Context: #{result.context}"
    puts "  Warnings: #{result.warnings.map(&:message)}"
    result.continue(result.value)
  }
end

result6 = tracking_pipeline.call(SimpleFlow::Result.new("data"))
puts "\nFinal result: #{result6.value}"
puts "Has warnings: #{result6.warnings.any?}"
puts "Is successful: #{result6.success?}"

puts "\n" + "=" * 60
puts "Examples completed!"
puts "=" * 60
