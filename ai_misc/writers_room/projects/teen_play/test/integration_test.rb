# frozen_string_literal: true

require "test_helper"

class IntegrationTest < Minitest::Test
  def setup
    # Skip if database is not configured
    unless ENV['TIGER_DBURL']
      skip "Database not configured. Set TIGER_DBURL to run integration tests."
    end

    # Initialize HTM with Ollama/gpt-oss via RubyLLM
    @htm = HTM.new(
      robot_name: "Test Robot",
      working_memory_size: 128_000,
      embedding_service: :ollama,
      embedding_model: 'gpt-oss'
    )
  end

  def teardown
    # Clean up test data if HTM was initialized
    return unless @htm

    begin
      # Forget test nodes
      ['test_decision_001', 'test_fact_001', 'test_code_001'].each do |key|
        @htm.forget(key, confirm: :confirmed) rescue nil
      end
    rescue => e
      # Ignore errors during cleanup
      puts "Cleanup warning: #{e.message}"
    end
  end

  def test_htm_initializes_with_ollama
    assert_instance_of HTM, @htm
    refute_nil @htm.robot_id
    assert_equal "Test Robot", @htm.robot_name
  end

  def test_add_node_with_embedding
    node_id = @htm.add_node(
      "test_decision_001",
      "We decided to use RubyLLM with Ollama provider and gpt-oss model for embeddings",
      type: :decision,
      category: "architecture",
      importance: 9.0,
      tags: ["testing", "embeddings", "ollama"]
    )

    assert_instance_of Integer, node_id
    assert node_id > 0
  end

  def test_retrieve_node
    # Add a test node
    @htm.add_node(
      "test_fact_001",
      "This is a test fact about HTM using Ollama embeddings",
      type: :fact,
      category: "testing",
      importance: 5.0
    )

    # Retrieve it
    node = @htm.retrieve("test_fact_001")
    refute_nil node
    assert_equal "test_fact_001", node['key']
    assert_includes node['value'], "test fact"
  end

  def test_add_multiple_nodes_with_relationships
    # Add first node
    @htm.add_node(
      "test_decision_001",
      "Decision to use Ollama",
      type: :decision,
      importance: 8.0
    )

    # Add second node with relationship
    @htm.add_node(
      "test_code_001",
      "Implementation code for Ollama integration",
      type: :code,
      importance: 7.0,
      related_to: ["test_decision_001"]
    )

    # Verify both exist
    node1 = @htm.retrieve("test_decision_001")
    node2 = @htm.retrieve("test_code_001")

    refute_nil node1
    refute_nil node2
  end

  def test_working_memory_tracking
    # Add a node and check working memory
    @htm.add_node(
      "test_fact_001",
      "Working memory test with Ollama embeddings",
      type: :fact,
      importance: 6.0
    )

    # Check working memory stats
    assert @htm.working_memory.node_count > 0
    assert @htm.working_memory.token_count > 0
    assert @htm.working_memory.utilization_percentage >= 0
  end

  def test_memory_stats
    # Add a test node
    @htm.add_node(
      "test_decision_001",
      "Testing memory statistics",
      type: :decision,
      importance: 5.0
    )

    # Get stats
    stats = @htm.memory_stats

    assert_instance_of Hash, stats
    assert stats.key?(:robot_id)
    assert stats.key?(:robot_name)
    assert stats.key?(:working_memory)
    assert stats[:working_memory].key?(:current_tokens)
    assert stats[:working_memory].key?(:max_tokens)
  end

  def test_create_context
    # Add some test nodes
    @htm.add_node(
      "test_fact_001",
      "Context test fact with Ollama",
      type: :fact,
      importance: 7.0
    )

    @htm.add_node(
      "test_decision_001",
      "Context test decision",
      type: :decision,
      importance: 8.0
    )

    # Create context
    context = @htm.create_context(strategy: :balanced)

    assert_instance_of String, context
    refute_empty context
  end

  def test_forget_with_confirmation
    # Add a node
    @htm.add_node(
      "test_fact_001",
      "This fact will be forgotten",
      type: :fact,
      importance: 1.0
    )

    # Verify it exists
    node = @htm.retrieve("test_fact_001")
    refute_nil node

    # Forget it
    result = @htm.forget("test_fact_001", confirm: :confirmed)
    assert result

    # Verify it's gone
    node = @htm.retrieve("test_fact_001")
    assert_nil node
  end

  def test_forget_requires_confirmation
    # Add a node
    @htm.add_node(
      "test_fact_001",
      "Testing confirmation requirement",
      type: :fact,
      importance: 1.0
    )

    # Try to forget without confirmation
    assert_raises(ArgumentError) do
      @htm.forget("test_fact_001")
    end

    # Verify it still exists
    node = @htm.retrieve("test_fact_001")
    refute_nil node

    # Clean up
    @htm.forget("test_fact_001", confirm: :confirmed)
  end
end
