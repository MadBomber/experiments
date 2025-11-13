#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/simple_flow'
require 'async/http/internet'
require 'json'

puts "=" * 80
puts "SimpleFlow - Async HTTP Fan-out Example"
puts "Demonstrates massive concurrency with fiber-based async execution"
puts "=" * 80

# Example 1: Sequential HTTP requests vs Concurrent
puts "\n1. Sequential vs Concurrent HTTP Requests"
puts "-" * 80

# Define a pipeline that fetches data from multiple APIs concurrently
pipeline = SimpleFlow::DagPipeline.new(name: :api_aggregator) do
  step :init, ->(result) {
    puts "  Initializing with user_id: #{result.value}"
    result.continue(result.value)
  }

  # These three API calls will run concurrently!
  step :fetch_user_profile, ->(result) {
    Async do
      puts "  [#{Time.now.strftime('%H:%M:%S.%L')}] Fetching user profile..."
      internet = Async::HTTP::Internet.new

      # Simulate API call to JSONPlaceholder
      response = internet.get("https://jsonplaceholder.typicode.com/users/#{result.value}")
      data = JSON.parse(response.read)

      puts "  [#{Time.now.strftime('%H:%M:%S.%L')}] ✓ Got user profile for: #{data['name']}"
      result.with_context(:profile, data).continue(result.value)
    end.wait
  }, depends_on: :init

  step :fetch_user_posts, ->(result) {
    Async do
      puts "  [#{Time.now.strftime('%H:%M:%S.%L')}] Fetching user posts..."
      internet = Async::HTTP::Internet.new

      response = internet.get("https://jsonplaceholder.typicode.com/posts?userId=#{result.value}")
      data = JSON.parse(response.read)

      puts "  [#{Time.now.strftime('%H:%M:%S.%L')}] ✓ Got #{data.length} posts"
      result.with_context(:posts, data).continue(result.value)
    end.wait
  }, depends_on: :init

  step :fetch_user_todos, ->(result) {
    Async do
      puts "  [#{Time.now.strftime('%H:%M:%S.%L')}] Fetching user todos..."
      internet = Async::HTTP::Internet.new

      response = internet.get("https://jsonplaceholder.typicode.com/todos?userId=#{result.value}")
      data = JSON.parse(response.read)

      puts "  [#{Time.now.strftime('%H:%M:%S.%L')}] ✓ Got #{data.length} todos"
      result.with_context(:todos, data).continue(result.value)
    end.wait
  }, depends_on: :init

  # This step waits for all three API calls to complete
  step :aggregate_data, ->(result) {
    profile = result.context[:fetch_user_profile_profile]
    posts = result.context[:fetch_user_posts_posts]
    todos = result.context[:fetch_user_todos_todos]

    aggregated = {
      user: {
        name: profile['name'],
        email: profile['email'],
        company: profile['company']['name']
      },
      stats: {
        total_posts: posts.length,
        total_todos: todos.length,
        completed_todos: todos.count { |t| t['completed'] }
      }
    }

    puts "\n  Aggregated data for #{profile['name']}:"
    puts "    Email: #{aggregated[:user][:email]}"
    puts "    Company: #{aggregated[:user][:company]}"
    puts "    Posts: #{aggregated[:stats][:total_posts]}"
    puts "    Todos: #{aggregated[:stats][:total_todos]} (#{aggregated[:stats][:completed_todos]} completed)"

    result.continue(aggregated)
  }, depends_on: [:fetch_user_profile, :fetch_user_posts, :fetch_user_todos]
end

puts "\nExecuting async pipeline (3 concurrent HTTP requests)..."
start_time = Time.now
result = pipeline.call(SimpleFlow::Result.new(1))
duration = Time.now - start_time

puts "\n✓ Pipeline completed in #{duration.round(2)}s"
puts "  (All 3 API calls ran concurrently!)"

# Example 2: Fan-out to Multiple Resources
puts "\n\n2. Fan-out Pattern: Fetching Multiple Users"
puts "-" * 80

multi_user_pipeline = SimpleFlow::DagPipeline.new(name: :multi_user_fetch) do
  step :init, ->(result) {
    result.continue(result.value) # array of user IDs
  }

  # Dynamically create steps for each user
  step :fetch_all_users, ->(result) {
    user_ids = result.value

    Async do |task|
      # Create a barrier for all user fetches
      barrier = Async::Barrier.new
      users = {}

      user_ids.each do |user_id|
        barrier.async do
          internet = Async::HTTP::Internet.new
          response = internet.get("https://jsonplaceholder.typicode.com/users/#{user_id}")
          data = JSON.parse(response.read)
          users[user_id] = data
          puts "  ✓ Fetched user #{user_id}: #{data['name']}"
        end
      end

      # Wait for all fetches to complete
      barrier.wait

      result.with_context(:users, users).continue(user_ids)
    end.wait
  }, depends_on: :init

  step :summarize, ->(result) {
    users = result.context[:fetch_all_users_users]

    puts "\n  Fetched #{users.size} users concurrently:"
    users.each do |id, user|
      puts "    - #{user['name']} (#{user['email']})"
    end

    result.continue(users)
  }, depends_on: :fetch_all_users
end

puts "\nFetching 5 users concurrently..."
start_time = Time.now
result = multi_user_pipeline.call(SimpleFlow::Result.new([1, 2, 3, 4, 5]))
duration = Time.now - start_time

puts "\n✓ Fetched all users in #{duration.round(2)}s"

# Example 3: Show Parallel Groups
puts "\n\n3. Visualizing Parallel Execution Groups"
puts "-" * 80

complex_pipeline = SimpleFlow::DagPipeline.new(name: :complex_flow) do
  step :start, ->(r) { r.continue(r.value) }

  step :task_a, ->(r) { r.continue(r.value) }, depends_on: :start
  step :task_b, ->(r) { r.continue(r.value) }, depends_on: :start
  step :task_c, ->(r) { r.continue(r.value) }, depends_on: :start

  step :task_d, ->(r) { r.continue(r.value) }, depends_on: [:task_a, :task_b]
  step :task_e, ->(r) { r.continue(r.value) }, depends_on: :task_c

  step :final, ->(r) { r.continue(r.value) }, depends_on: [:task_d, :task_e]
end

puts "\nExecution groups (concurrent waves):"
complex_pipeline.parallel_groups.each_with_index do |group, i|
  puts "  Wave #{i + 1}: #{group.join(', ')}"
  puts "    (All steps in this wave run concurrently)"
end

# Example 4: Error Handling in Async Pipelines
puts "\n\n4. Error Handling with Async"
puts "-" * 80

error_pipeline = SimpleFlow::DagPipeline.new(name: :error_handling) do
  step :valid_request, ->(result) {
    Async do
      puts "  Making valid request..."
      internet = Async::HTTP::Internet.new
      response = internet.get("https://jsonplaceholder.typicode.com/users/1")
      data = JSON.parse(response.read)
      puts "  ✓ Valid request succeeded"
      result.with_context(:user, data).continue(result.value)
    end.wait
  }

  step :invalid_request, ->(result) {
    Async do
      puts "  Making invalid request (will fail)..."
      internet = Async::HTTP::Internet.new
      response = internet.get("https://jsonplaceholder.typicode.com/invalid/endpoint")

      if response.status != 200
        puts "  ✗ Request failed with status #{response.status}"
        result.halt.with_error(
          :http_error,
          "Request failed: #{response.status}",
          severity: :error
        ).continue(result.value)
      else
        result.continue(result.value)
      end
    end.wait
  }, depends_on: :valid_request
end

puts "\nTesting error handling..."
result = error_pipeline.call(SimpleFlow::Result.new(nil))

if result.errors?
  puts "\n✓ Errors were captured:"
  result.all_errors.each do |error|
    puts "  - #{error.message}"
  end
else
  puts "\nNo errors occurred"
end

puts "\n" + "=" * 80
puts "Async Examples Completed!"
puts "=" * 80
puts "\nKey Takeaways:"
puts "  • Async fibers enable massive concurrency (1000s of operations)"
puts "  • Perfect for I/O-bound work (HTTP, DB, files)"
puts "  • Automatic coordination via Async::Barrier"
puts "  • Much lighter than threads (~4KB vs ~1MB per operation)"
puts "=" * 80
