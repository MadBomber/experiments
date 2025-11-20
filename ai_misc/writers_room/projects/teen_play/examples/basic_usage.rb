#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic usage example for HTM
#
# Prerequisites:
# 1. Source environment variables: source ~/.bashrc__tiger
# 2. Initialize database schema: ruby -r ./lib/htm -e "HTM::Database.setup"
# 3. Install dependencies: bundle install

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "htm"

puts "HTM Basic Usage Example"
puts "=" * 60

# Check environment
unless ENV['TIGER_DBURL']
  puts "ERROR: TIGER_DBURL not set. Please run: source ~/.bashrc__tiger"
  exit 1
end

begin
  # Initialize HTM with Ollama embedding service
  puts "\n1. Initializing HTM for 'Code Helper' robot..."
  puts "   Using RubyLLM with Ollama provider and gpt-oss model for embeddings"
  htm = HTM.new(
    robot_name: "Code Helper",
    working_memory_size: 128_000,
    embedding_service: :ollama,       # Use Ollama via RubyLLM
    embedding_model: 'gpt-oss'        # gpt-oss model for embeddings
  )
  puts "✓ HTM initialized"
  puts "  Robot ID: #{htm.robot_id}"
  puts "  Robot Name: #{htm.robot_name}"
  puts "  Embedding Service: Ollama (gpt-oss via RubyLLM)"

  # Add some memory nodes
  puts "\n2. Adding memory nodes..."

  htm.add_node(
    "decision_001",
    "We decided to use PostgreSQL with TimescaleDB for HTM storage because it provides excellent time-series optimization and native vector search with pgvector.",
    type: :decision,
    category: "architecture",
    importance: 9.0,
    tags: ["architecture", "database", "HTM"]
  )
  puts "✓ Added decision about database choice"

  htm.add_node(
    "decision_002",
    "We chose RAG (Retrieval-Augmented Generation) for memory recall, combining temporal filtering with semantic vector search.",
    type: :decision,
    category: "architecture",
    importance: 8.5,
    tags: ["architecture", "RAG", "search"],
    related_to: ["decision_001"]
  )
  puts "✓ Added decision about RAG approach"

  htm.add_node(
    "fact_001",
    "The user's name is Dewayne and they prefer using debug_me for debugging instead of puts.",
    type: :fact,
    category: "preferences",
    importance: 7.0,
    tags: ["user", "preferences"]
  )
  puts "✓ Added fact about user preferences"

  # Check working memory stats
  puts "\n3. Working Memory Status:"
  puts "  Total nodes: #{htm.working_memory.node_count}"
  puts "  Total tokens: #{htm.working_memory.token_count}"
  puts "  Utilization: #{htm.working_memory.utilization_percentage}%"

  # Retrieve a specific node
  puts "\n4. Retrieving specific memory..."
  node = htm.retrieve("decision_001")
  if node
    puts "✓ Found: #{node['value'][0..100]}..."
  end

  # Get memory statistics
  puts "\n5. Memory Statistics:"
  stats = htm.memory_stats
  puts "  Total nodes in long-term memory: #{stats[:total_nodes]}"
  puts "  Active robots: #{stats[:active_robots]}"
  puts "  Database size: #{(stats[:database_size] / (1024.0 * 1024.0)).round(2)} MB"

  # Simulate time passing and recall
  puts "\n6. Simulating recall from 'last week'..."
  puts "  (Note: Since we just added these, timeframe search won't find them)"
  puts "  In production, you would do:"
  puts "    memories = htm.recall(timeframe: 'last week', topic: 'database')"

  # Create context for LLM
  puts "\n7. Creating context for LLM (balanced strategy)..."
  context = htm.create_context(strategy: :balanced, max_tokens: 10_000)
  puts "✓ Context created (#{context.length} characters)"
  puts "\nContext preview:"
  puts context[0..200] + "..."

  puts "\n" + "=" * 60
  puts "✓ Example completed successfully!"
  puts "\nNext steps:"
  puts "  - Try adding more nodes with different types"
  puts "  - Experiment with recall using different timeframes"
  puts "  - Test the relationship graph with get_related_nodes"
  puts "  - Check which_robot_said to see hive mind in action"

rescue => e
  puts "\n✗ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end
