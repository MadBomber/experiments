# frozen_string_literal: true

require_relative "htm/version"
require_relative "htm/database"
require_relative "htm/long_term_memory"
require_relative "htm/working_memory"
require_relative "htm/embedding_service"

require "pg"
require "pgvector"
require "connection_pool"
require "securerandom"
require "uri"

# HTM (Hierarchical Temporary Memory) - Intelligent memory management for LLM robots
#
# HTM implements a two-tier memory system:
# - Working Memory: Token-limited, active context for immediate LLM use
# - Long-term Memory: Durable PostgreSQL/TimescaleDB storage for permanent knowledge
#
# Key Features:
# - Never forgets unless explicitly told
# - RAG-based retrieval (temporal + semantic search)
# - Multi-robot "hive mind" - all robots share global memory
# - Relationship graphs for knowledge connections
# - Time-series optimized with TimescaleDB
#
# @example Basic usage
#   htm = HTM.new(robot_name: "Code Helper")
#
#   # Add memories
#   htm.add_node("decision_001", "We decided to use PostgreSQL for HTM",
#                type: :decision, importance: 8.0, tags: ["architecture"])
#
#   # Recall from the past
#   memories = htm.recall(timeframe: "last week", topic: "PostgreSQL")
#
#   # Create context for LLM
#   context = htm.create_context(strategy: :balanced)
#
class HTM
  attr_reader :robot_id, :robot_name, :working_memory, :long_term_memory

  # Initialize a new HTM instance
  #
  # @param working_memory_size [Integer] Maximum tokens for working memory (default: 128,000)
  # @param robot_id [String] Unique identifier for this robot (auto-generated if not provided)
  # @param robot_name [String] Human-readable name for this robot
  # @param db_config [Hash] Database configuration (uses ENV['TIGER_DBURL'] if not provided)
  # @param embedding_service [Symbol] Embedding service to use (:ollama, :openai, :cohere, :local) (default: :ollama)
  # @param embedding_model [String] Model name for embedding service (default: 'gpt-oss' for ollama)
  #
  def initialize(
    working_memory_size: 128_000,
    robot_id: nil,
    robot_name: nil,
    db_config: nil,
    embedding_service: :ollama,
    embedding_model: 'gpt-oss'
  )
    @robot_id = robot_id || SecureRandom.uuid
    @robot_name = robot_name || "robot_#{@robot_id[0..7]}"

    # Initialize components
    @working_memory = HTM::WorkingMemory.new(max_tokens: working_memory_size)
    @long_term_memory = HTM::LongTermMemory.new(db_config || HTM::Database.default_config)
    @embedding_service = HTM::EmbeddingService.new(embedding_service, model: embedding_model)

    # Register this robot in the database
    register_robot
  end

  # Add a new memory node
  #
  # @param key [String] Unique identifier for this node
  # @param value [String] Content of the memory
  # @param type [Symbol] Type of memory (:fact, :context, :code, :preference, :decision, :question)
  # @param category [String] Optional category for organization
  # @param importance [Float] Importance score (0.0-10.0, default: 1.0)
  # @param related_to [Array<String>] Keys of related nodes
  # @param tags [Array<String>] Tags for categorization
  # @return [Integer] Database ID of the created node
  #
  def add_node(key, value, type: nil, category: nil, importance: 1.0, related_to: [], tags: [])
    # Generate embedding
    embedding = @embedding_service.embed(value)

    # Calculate token count
    token_count = @embedding_service.count_tokens(value)

    # Store in long-term memory
    node_id = @long_term_memory.add(
      key: key,
      value: value,
      type: type,
      category: category,
      importance: importance,
      token_count: token_count,
      robot_id: @robot_id,
      embedding: embedding
    )

    # Add relationships
    related_to.each do |related_key|
      @long_term_memory.add_relationship(from: key, to: related_key)
    end

    # Add tags
    tags.each do |tag|
      @long_term_memory.add_tag(node_id: node_id, tag: tag)
    end

    # Add to working memory
    @working_memory.add(key, value, token_count: token_count, importance: importance)

    # Log the operation
    @long_term_memory.log_operation(
      operation: 'add',
      node_id: node_id,
      robot_id: @robot_id,
      details: { key: key, type: type }
    )

    update_robot_activity
    node_id
  end

  # Recall memories from a timeframe and topic
  #
  # @param timeframe [String, Range] Time range ("last week", 7.days.ago..Time.now)
  # @param topic [String] Topic to search for
  # @param limit [Integer] Maximum number of nodes to retrieve (default: 20)
  # @param strategy [Symbol] Search strategy (:vector, :fulltext, :hybrid)
  # @return [Array<Hash>] Retrieved memory nodes
  #
  def recall(timeframe:, topic:, limit: 20, strategy: :vector)
    parsed_timeframe = parse_timeframe(timeframe)

    # Perform RAG-based retrieval
    nodes = case strategy
    when :vector
      @long_term_memory.search(
        timeframe: parsed_timeframe,
        query: topic,
        limit: limit,
        embedding_service: @embedding_service
      )
    when :fulltext
      @long_term_memory.search_fulltext(
        timeframe: parsed_timeframe,
        query: topic,
        limit: limit
      )
    when :hybrid
      @long_term_memory.search_hybrid(
        timeframe: parsed_timeframe,
        query: topic,
        limit: limit,
        embedding_service: @embedding_service
      )
    end

    # Add to working memory (evict if needed)
    nodes.each do |node|
      add_to_working_memory(node)
    end

    # Log the operation
    @long_term_memory.log_operation(
      operation: 'recall',
      node_id: nil,
      robot_id: @robot_id,
      details: { timeframe: timeframe.to_s, topic: topic, count: nodes.length }
    )

    update_robot_activity
    nodes
  end

  # Retrieve a specific memory node
  #
  # @param key [String] Key of the node to retrieve
  # @return [Hash, nil] The node data or nil if not found
  #
  def retrieve(key)
    node = @long_term_memory.retrieve(key)
    if node
      @long_term_memory.update_last_accessed(key)
      @long_term_memory.log_operation(
        operation: 'retrieve',
        node_id: node['id'],
        robot_id: @robot_id,
        details: { key: key }
      )
    end
    node
  end

  # Forget a memory node (explicit deletion)
  #
  # @param key [String] Key of the node to delete
  # @param confirm [Symbol] Must be :confirmed to proceed
  # @return [Boolean] true if deleted, false otherwise
  #
  def forget(key, confirm: false)
    raise ArgumentError, "Must pass confirm: :confirmed to delete" unless confirm == :confirmed

    node_id = @long_term_memory.get_node_id(key)
    @long_term_memory.delete(key)
    @working_memory.remove(key)

    @long_term_memory.log_operation(
      operation: 'forget',
      node_id: node_id,
      robot_id: @robot_id,
      details: { key: key }
    )

    update_robot_activity
    true
  end

  # Create context string for LLM
  #
  # @param strategy [Symbol] Assembly strategy (:recent, :important, :balanced)
  # @param max_tokens [Integer] Optional token limit
  # @return [String] Assembled context
  #
  def create_context(strategy: :balanced, max_tokens: nil)
    @working_memory.assemble_context(strategy: strategy, max_tokens: max_tokens)
  end

  # Get memory statistics
  #
  # @return [Hash] Statistics about memory usage
  #
  def memory_stats
    @long_term_memory.stats.merge({
      robot_id: @robot_id,
      robot_name: @robot_name,
      working_memory: {
        current_tokens: @working_memory.token_count,
        max_tokens: @working_memory.max_tokens,
        utilization: @working_memory.utilization_percentage,
        node_count: @working_memory.node_count
      }
    })
  end

  # Which robot discussed a topic?
  #
  # @param topic [String] Topic to search for
  # @param limit [Integer] Maximum results (default: 100)
  # @return [Hash] Robot IDs mapped to mention counts
  #
  def which_robot_said(topic, limit: 100)
    results = @long_term_memory.search_fulltext(
      timeframe: (Time.at(0)..Time.now),
      query: topic,
      limit: limit
    )

    results.group_by { |n| n['robot_id'] }
           .transform_values(&:count)
  end

  # Get chronological conversation timeline
  #
  # @param topic [String] Topic to search for
  # @param limit [Integer] Maximum results (default: 50)
  # @return [Array<Hash>] Timeline of memories
  #
  def conversation_timeline(topic, limit: 50)
    results = @long_term_memory.search_fulltext(
      timeframe: (Time.at(0)..Time.now),
      query: topic,
      limit: limit
    )

    results.sort_by { |n| n['created_at'] }
           .map { |n| {
             timestamp: n['created_at'],
             robot: n['robot_id'],
             content: n['value'],
             type: n['type']
           }}
  end

  private

  def register_robot
    @long_term_memory.register_robot(@robot_id, @robot_name)
  end

  def update_robot_activity
    @long_term_memory.update_robot_activity(@robot_id)
  end

  def add_to_working_memory(node)
    if @working_memory.has_space?(node['token_count'])
      @working_memory.add(
        node['key'],
        node['value'],
        token_count: node['token_count'],
        importance: node['importance'],
        from_recall: true
      )
    else
      # Evict to make space
      evicted = @working_memory.evict_to_make_space(node['token_count'])
      evicted_keys = evicted.map { |n| n[:key] }
      @long_term_memory.mark_evicted(evicted_keys) if evicted_keys.any?

      # Now add the recalled node
      @working_memory.add(
        node['key'],
        node['value'],
        token_count: node['token_count'],
        importance: node['importance'],
        from_recall: true
      )
    end
  end

  def parse_timeframe(timeframe)
    case timeframe
    when Range
      timeframe
    when String
      parse_natural_timeframe(timeframe)
    else
      raise ArgumentError, "Invalid timeframe: #{timeframe}"
    end
  end

  def parse_natural_timeframe(text)
    now = Time.now

    case text.downcase
    when /last week/
      (now - 7 * 24 * 3600)..now
    when /yesterday/
      start_of_yesterday = Time.new(now.year, now.month, now.day - 1)
      start_of_yesterday..(start_of_yesterday + 24 * 3600)
    when /last (\d+) days?/
      days = $1.to_i
      (now - days * 24 * 3600)..now
    when /this month/
      start_of_month = Time.new(now.year, now.month, 1)
      start_of_month..now
    when /last month/
      start_of_last_month = Time.new(now.year, now.month - 1, 1)
      end_of_last_month = Time.new(now.year, now.month, 1) - 1
      start_of_last_month..end_of_last_month
    else
      # Default to last 24 hours
      (now - 24 * 3600)..now
    end
  end
end
