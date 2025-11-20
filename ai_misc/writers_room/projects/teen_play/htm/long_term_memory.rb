# frozen_string_literal: true

require 'pg'
require 'pgvector'
require 'json'

class HTM
  # Long-term Memory - PostgreSQL/TimescaleDB-backed permanent storage
  #
  # LongTermMemory provides durable storage for all memory nodes with:
  # - Vector similarity search (RAG)
  # - Full-text search
  # - Time-range queries
  # - Relationship graphs
  # - Tag system
  #
  class LongTermMemory
    def initialize(config)
      @config = config
      raise "Database configuration required" unless @config
    end

    # Add a node to long-term memory
    #
    # @param key [String] Node identifier
    # @param value [String] Node content
    # @param type [String, nil] Node type
    # @param category [String, nil] Node category
    # @param importance [Float] Importance score
    # @param token_count [Integer] Token count
    # @param robot_id [String] Robot identifier
    # @param embedding [Array<Float>] Vector embedding
    # @return [Integer] Node database ID
    #
    def add(key:, value:, type: nil, category: nil, importance: 1.0, token_count: 0, robot_id:, embedding:)
      with_connection do |conn|
        result = conn.exec_params(
          <<~SQL,
            INSERT INTO nodes (key, value, type, category, importance, token_count, robot_id, embedding)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8::vector)
            RETURNING id
          SQL
          [key, value, type, category, importance, token_count, robot_id, embedding.to_s]
        )
        result.first['id'].to_i
      end
    end

    # Retrieve a node by key
    #
    # @param key [String] Node identifier
    # @return [Hash, nil] Node data or nil
    #
    def retrieve(key)
      with_connection do |conn|
        result = conn.exec_params("SELECT * FROM nodes WHERE key = $1", [key])
        result.first
      end
    end

    # Update last_accessed timestamp
    #
    # @param key [String] Node identifier
    # @return [void]
    #
    def update_last_accessed(key)
      with_connection do |conn|
        conn.exec_params(
          "UPDATE nodes SET last_accessed = CURRENT_TIMESTAMP WHERE key = $1",
          [key]
        )
      end
    end

    # Delete a node
    #
    # @param key [String] Node identifier
    # @return [void]
    #
    def delete(key)
      with_connection do |conn|
        conn.exec_params("DELETE FROM nodes WHERE key = $1", [key])
      end
    end

    # Get node database ID
    #
    # @param key [String] Node identifier
    # @return [Integer, nil] Database ID or nil
    #
    def get_node_id(key)
      with_connection do |conn|
        result = conn.exec_params("SELECT id FROM nodes WHERE key = $1", [key])
        result.first&.fetch('id')&.to_i
      end
    end

    # Vector similarity search
    #
    # @param timeframe [Range] Time range to search
    # @param query [String] Search query
    # @param limit [Integer] Maximum results
    # @param embedding_service [Object] Service to generate embeddings
    # @return [Array<Hash>] Matching nodes
    #
    def search(timeframe:, query:, limit:, embedding_service:)
      query_embedding = embedding_service.embed(query)

      with_connection do |conn|
        result = conn.exec_params(
          <<~SQL,
            SELECT id, key, value, type, category, importance, created_at, robot_id, token_count,
                   1 - (embedding <=> $1::vector) as similarity
            FROM nodes
            WHERE created_at BETWEEN $2 AND $3
            ORDER BY embedding <=> $1::vector
            LIMIT $4
          SQL
          [query_embedding.to_s, timeframe.begin, timeframe.end, limit]
        )
        result.to_a
      end
    end

    # Full-text search
    #
    # @param timeframe [Range] Time range to search
    # @param query [String] Search query
    # @param limit [Integer] Maximum results
    # @return [Array<Hash>] Matching nodes
    #
    def search_fulltext(timeframe:, query:, limit:)
      with_connection do |conn|
        result = conn.exec_params(
          <<~SQL,
            SELECT id, key, value, type, category, importance, created_at, robot_id, token_count,
                   ts_rank(to_tsvector('english', value), plainto_tsquery('english', $1)) as rank
            FROM nodes
            WHERE created_at BETWEEN $2 AND $3
            AND to_tsvector('english', value) @@ plainto_tsquery('english', $1)
            ORDER BY rank DESC
            LIMIT $4
          SQL
          [query, timeframe.begin, timeframe.end, limit]
        )
        result.to_a
      end
    end

    # Hybrid search (full-text + vector)
    #
    # @param timeframe [Range] Time range to search
    # @param query [String] Search query
    # @param limit [Integer] Maximum results
    # @param embedding_service [Object] Service to generate embeddings
    # @param prefilter_limit [Integer] Candidates to consider (default: 100)
    # @return [Array<Hash>] Matching nodes
    #
    def search_hybrid(timeframe:, query:, limit:, embedding_service:, prefilter_limit: 100)
      query_embedding = embedding_service.embed(query)

      with_connection do |conn|
        result = conn.exec_params(
          <<~SQL,
            WITH candidates AS (
              SELECT id, key, value, type, category, importance, created_at, robot_id, token_count, embedding
              FROM nodes
              WHERE created_at BETWEEN $2 AND $3
              AND to_tsvector('english', value) @@ plainto_tsquery('english', $1)
              LIMIT $5
            )
            SELECT id, key, value, type, category, importance, created_at, robot_id, token_count,
                   1 - (embedding <=> $4::vector) as similarity
            FROM candidates
            ORDER BY embedding <=> $4::vector
            LIMIT $6
          SQL
          [query, timeframe.begin, timeframe.end, query_embedding.to_s, prefilter_limit, limit]
        )
        result.to_a
      end
    end

    # Add a relationship between nodes
    #
    # @param from [String] From node key
    # @param to [String] To node key
    # @param type [String, nil] Relationship type
    # @param strength [Float] Relationship strength
    # @return [void]
    #
    def add_relationship(from:, to:, type: nil, strength: 1.0)
      with_connection do |conn|
        from_id = get_node_id(from)
        to_id = get_node_id(to)
        return unless from_id && to_id

        conn.exec_params(
          <<~SQL,
            INSERT INTO relationships (from_node_id, to_node_id, relationship_type, strength)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (from_node_id, to_node_id, relationship_type) DO NOTHING
          SQL
          [from_id, to_id, type, strength]
        )
      end
    end

    # Add a tag to a node
    #
    # @param node_id [Integer] Node database ID
    # @param tag [String] Tag name
    # @return [void]
    #
    def add_tag(node_id:, tag:)
      with_connection do |conn|
        conn.exec_params(
          "INSERT INTO tags (node_id, tag) VALUES ($1, $2) ON CONFLICT DO NOTHING",
          [node_id, tag]
        )
      end
    end

    # Mark nodes as evicted from working memory
    #
    # @param keys [Array<String>] Node keys
    # @return [void]
    #
    def mark_evicted(keys)
      return if keys.empty?

      with_connection do |conn|
        conn.exec_params(
          "UPDATE nodes SET in_working_memory = FALSE WHERE key = ANY($1::text[])",
          [keys]
        )
      end
    end

    # Register a robot
    #
    # @param robot_id [String] Robot identifier
    # @param robot_name [String] Robot name
    # @return [void]
    #
    def register_robot(robot_id, robot_name)
      with_connection do |conn|
        conn.exec_params(
          <<~SQL,
            INSERT INTO robots (id, name)
            VALUES ($1, $2)
            ON CONFLICT (id) DO UPDATE SET name = $2, last_active = CURRENT_TIMESTAMP
          SQL
          [robot_id, robot_name]
        )
      end
    end

    # Update robot activity timestamp
    #
    # @param robot_id [String] Robot identifier
    # @return [void]
    #
    def update_robot_activity(robot_id)
      with_connection do |conn|
        conn.exec_params(
          "UPDATE robots SET last_active = CURRENT_TIMESTAMP WHERE id = $1",
          [robot_id]
        )
      end
    end

    # Log an operation
    #
    # @param operation [String] Operation type
    # @param node_id [Integer, nil] Node database ID
    # @param robot_id [String] Robot identifier
    # @param details [Hash] Operation details
    # @return [void]
    #
    def log_operation(operation:, node_id:, robot_id:, details:)
      with_connection do |conn|
        conn.exec_params(
          "INSERT INTO operations_log (operation, node_id, robot_id, details) VALUES ($1, $2, $3, $4)",
          [operation, node_id, robot_id, details.to_json]
        )
      end
    end

    # Get memory statistics
    #
    # @return [Hash] Statistics
    #
    def stats
      with_connection do |conn|
        {
          total_nodes: conn.exec("SELECT COUNT(*) FROM nodes").first['count'].to_i,
          nodes_by_robot: conn.exec(
            "SELECT robot_id, COUNT(*) as count FROM nodes GROUP BY robot_id"
          ).to_a.map { |r| [r['robot_id'], r['count'].to_i] }.to_h,
          nodes_by_type: conn.exec("SELECT * FROM node_stats").to_a,
          total_relationships: conn.exec("SELECT COUNT(*) FROM relationships").first['count'].to_i,
          total_tags: conn.exec("SELECT COUNT(*) FROM tags").first['count'].to_i,
          oldest_memory: conn.exec("SELECT MIN(created_at) FROM nodes").first['min'],
          newest_memory: conn.exec("SELECT MAX(created_at) FROM nodes").first['max'],
          active_robots: conn.exec("SELECT COUNT(*) FROM robots").first['count'].to_i,
          robot_activity: conn.exec("SELECT * FROM robot_activity").to_a,
          database_size: conn.exec("SELECT pg_database_size(current_database())").first['pg_database_size'].to_i
        }
      end
    end

    private

    def with_connection
      conn = PG.connect(@config)
      # Pgvector is automatically available after requiring 'pgvector'
      # No explicit registration needed
      result = yield(conn)
      conn.close
      result
    rescue => e
      conn&.close
      raise e
    end
  end
end
