# frozen_string_literal: true

class HTM
  # Working Memory - Token-limited active context for immediate LLM use
  #
  # WorkingMemory manages the active conversation context within token limits.
  # When full, it evicts less important or older nodes back to long-term storage.
  #
  class WorkingMemory
    attr_reader :max_tokens

    # Initialize working memory
    #
    # @param max_tokens [Integer] Maximum tokens allowed in working memory
    #
    def initialize(max_tokens:)
      @max_tokens = max_tokens
      @nodes = {}
      @access_order = []
    end

    # Add a node to working memory
    #
    # @param key [String] Node identifier
    # @param value [String] Node content
    # @param token_count [Integer] Number of tokens in this node
    # @param importance [Float] Importance score (0.0-10.0)
    # @param from_recall [Boolean] Whether this node was recalled from long-term memory
    # @return [void]
    #
    def add(key, value, token_count:, importance: 1.0, from_recall: false)
      @nodes[key] = {
        value: value,
        token_count: token_count,
        importance: importance,
        added_at: Time.now,
        from_recall: from_recall
      }
      update_access(key)
    end

    # Remove a node from working memory
    #
    # @param key [String] Node identifier
    # @return [void]
    #
    def remove(key)
      @nodes.delete(key)
      @access_order.delete(key)
    end

    # Check if there's space for a node
    #
    # @param token_count [Integer] Number of tokens needed
    # @return [Boolean] true if space available
    #
    def has_space?(token_count)
      current_tokens + token_count <= @max_tokens
    end

    # Evict nodes to make space
    #
    # @param needed_tokens [Integer] Number of tokens needed
    # @return [Array<Hash>] Evicted nodes
    #
    def evict_to_make_space(needed_tokens)
      evicted = []
      tokens_freed = 0

      # Sort by importance and recency (lower importance and older first)
      candidates = @nodes.sort_by do |key, node|
        recency = Time.now - node[:added_at]
        [node[:importance], -recency]
      end

      candidates.each do |key, node|
        break if tokens_freed >= needed_tokens

        evicted << { key: key, value: node[:value] }
        tokens_freed += node[:token_count]
        @nodes.delete(key)
        @access_order.delete(key)
      end

      evicted
    end

    # Assemble context string for LLM
    #
    # @param strategy [Symbol] Assembly strategy (:recent, :important, :balanced)
    # @param max_tokens [Integer, nil] Optional token limit
    # @return [String] Assembled context
    #
    def assemble_context(strategy:, max_tokens: nil)
      max = max_tokens || @max_tokens

      nodes = case strategy
      when :recent
        @access_order.reverse.map { |k| @nodes[k] }
      when :important
        @nodes.sort_by { |k, v| -v[:importance] }.map(&:last)
      when :balanced
        @nodes.sort_by { |k, v|
          recency = Time.now - v[:added_at]
          -(v[:importance] * (1.0 / (1 + recency / 3600.0)))
        }.map(&:last)
      else
        raise ArgumentError, "Unknown strategy: #{strategy}"
      end

      # Build context up to token limit
      context_parts = []
      current_tokens = 0

      nodes.each do |node|
        break if current_tokens + node[:token_count] > max
        context_parts << node[:value]
        current_tokens += node[:token_count]
      end

      context_parts.join("\n\n")
    end

    # Get current token count
    #
    # @return [Integer] Total tokens in working memory
    #
    def token_count
      @nodes.values.sum { |n| n[:token_count] }
    end

    # Get utilization percentage
    #
    # @return [Float] Percentage of working memory used
    #
    def utilization_percentage
      (token_count.to_f / @max_tokens * 100).round(2)
    end

    # Get node count
    #
    # @return [Integer] Number of nodes in working memory
    #
    def node_count
      @nodes.size
    end

    private

    def current_tokens
      token_count
    end

    def update_access(key)
      @access_order.delete(key)
      @access_order << key
    end
  end
end
