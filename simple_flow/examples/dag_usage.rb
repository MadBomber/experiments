#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/simple_flow'

puts "=" * 60
puts "SimpleFlow - DAG Pipeline Example"
puts "=" * 60

# Example 1: Basic DAG with Dependencies
puts "\n1. Basic DAG with Dependencies"
puts "-" * 60

dag = SimpleFlow::DagPipeline.new(name: :user_data_fetcher) do
  step :fetch_user, ->(result) {
    puts "  Fetching user #{result.value}..."
    sleep 0.1
    result.with_context(:user, { id: result.value, name: "User #{result.value}" })
          .continue(result.value)
  }

  step :fetch_posts, ->(result) {
    puts "  Fetching posts for user #{result.value}..."
    sleep 0.2
    result.with_context(:posts, ["Post 1", "Post 2"])
          .continue(result.value)
  }, depends_on: :fetch_user

  step :fetch_comments, ->(result) {
    puts "  Fetching comments for user #{result.value}..."
    sleep 0.2
    result.with_context(:comments, ["Comment 1", "Comment 2", "Comment 3"])
          .continue(result.value)
  }, depends_on: :fetch_user

  step :combine_data, ->(result) {
    puts "  Combining all data..."
    user = result.context[:fetch_user_user]
    posts = result.context[:fetch_posts_posts]
    comments = result.context[:fetch_comments_comments]

    combined = {
      user: user,
      posts: posts,
      comments: comments
    }

    result.continue(combined)
  }, depends_on: [:fetch_posts, :fetch_comments]
end

# Show execution order
puts "\nExecution order (topologically sorted):"
puts dag.sorted_steps.map { |s| "  - #{s}" }.join("\n")

# Show parallel groups
puts "\nParallel execution groups:"
dag.parallel_groups.each_with_index do |group, i|
  puts "  Group #{i + 1}: #{group.join(', ')}"
end

# Execute serially
puts "\nExecuting serially:"
start_time = Time.now
result = dag.call(SimpleFlow::Result.new(123))
serial_duration = Time.now - start_time

puts "\nSerial execution took: #{serial_duration.round(3)}s"
puts "Result: #{result.value}"

# Execute in parallel
puts "\nExecuting in parallel:"
start_time = Time.now
result2 = dag.call_parallel(SimpleFlow::Result.new(456))
parallel_duration = Time.now - start_time

puts "\nParallel execution took: #{parallel_duration.round(3)}s"
puts "Result: #{result2.value}"
puts "\nSpeedup: #{(serial_duration / parallel_duration).round(2)}x"

# Example 2: Complex DAG with Multiple Levels
puts "\n2. Complex Multi-Level DAG"
puts "-" * 60

complex_dag = SimpleFlow::DagPipeline.new do
  # Level 1
  step :init, ->(r) {
    puts "  [Level 1] Initializing..."
    r.continue(r.value + 1)
  }

  # Level 2 - depends on init
  step :parse_a, ->(r) {
    puts "  [Level 2] Parsing A..."
    r.continue(r.value)
  }, depends_on: :init

  step :parse_b, ->(r) {
    puts "  [Level 2] Parsing B..."
    r.continue(r.value)
  }, depends_on: :init

  # Level 3 - depends on parsing
  step :validate_a, ->(r) {
    puts "  [Level 3] Validating A..."
    r.continue(r.value)
  }, depends_on: :parse_a

  step :validate_b, ->(r) {
    puts "  [Level 3] Validating B..."
    r.continue(r.value)
  }, depends_on: :parse_b

  # Level 4 - depends on validation
  step :finalize, ->(r) {
    puts "  [Level 4] Finalizing..."
    r.continue(r.value * 10)
  }, depends_on: [:validate_a, :validate_b]
end

puts "\nParallel groups:"
complex_dag.parallel_groups.each_with_index do |group, i|
  puts "  Level #{i + 1}: #{group.join(', ')}"
end

puts "\nExecuting:"
result3 = complex_dag.call_parallel(SimpleFlow::Result.new(5))
puts "\nFinal result: #{result3.value}"

# Example 3: Subgraph Extraction
puts "\n3. Subgraph Extraction"
puts "-" * 60

full_dag = SimpleFlow::DagPipeline.new do
  step :a, ->(r) { r.continue(r.value + 1) }
  step :b, ->(r) { r.continue(r.value * 2) }, depends_on: :a
  step :c, ->(r) { r.continue(r.value + 10) }, depends_on: :b
  step :unrelated_x, ->(r) { r.continue(999) }
  step :unrelated_y, ->(r) { r.continue(888) }, depends_on: :unrelated_x
end

puts "Full DAG steps: #{full_dag.sorted_steps.join(', ')}"

subgraph = full_dag.subgraph(:c)
puts "Subgraph for :c steps: #{subgraph.sorted_steps.join(', ')}"

result4 = subgraph.call(SimpleFlow::Result.new(0))
puts "Subgraph result: #{result4.value} (expected: #{(0 + 1) * 2 + 10})"

# Example 4: DAG Pipeline Merging
puts "\n4. DAG Pipeline Merging"
puts "-" * 60

dag1 = SimpleFlow::DagPipeline.new do
  step :load_data, ->(r) {
    puts "  Loading data..."
    r.continue(r.value)
  }

  step :clean_data, ->(r) {
    puts "  Cleaning data..."
    r.continue(r.value)
  }, depends_on: :load_data
end

dag2 = SimpleFlow::DagPipeline.new do
  step :analyze_data, ->(r) {
    puts "  Analyzing data..."
    r.continue(r.value)
  }, depends_on: :clean_data

  step :generate_report, ->(r) {
    puts "  Generating report..."
    r.continue("Report for: #{r.value}")
  }, depends_on: :analyze_data
end

merged = dag1.merge(dag2)
puts "Merged DAG steps: #{merged.sorted_steps.join(' → ')}"

result5 = merged.call(SimpleFlow::Result.new("Dataset X"))
puts "Result: #{result5.value}"

# Example 5: Circular Dependency Detection
puts "\n5. Circular Dependency Detection"
puts "-" * 60

begin
  circular_dag = SimpleFlow::DagPipeline.new do
    step :a, ->(r) { r }, depends_on: :c
    step :b, ->(r) { r }, depends_on: :a
    step :c, ->(r) { r }, depends_on: :b
  end

  circular_dag.call(SimpleFlow::Result.new(0))
rescue SimpleFlow::CircularDependencyError => e
  puts "✓ Caught circular dependency: #{e.message}"
end

puts "\n" + "=" * 60
puts "DAG Examples completed!"
puts "=" * 60
