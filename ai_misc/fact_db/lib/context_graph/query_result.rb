# frozen_string_literal: true

module ContextGraph
  # Holds the results of a query across multiple stores.
  # Provides a unified interface for transformers to work with.
  class QueryResult
    attr_reader :query, :facts, :memories, :entities, :metadata

    def initialize(query:)
      @query = query
      @facts = []
      @memories = []
      @entities = {}
      @metadata = {
        retrieved_at: Time.now,
        stores_queried: []
      }
    end

    # Add facts from FactDB
    def add_facts(facts)
      return if facts.nil? || facts.empty?

      @facts += normalize_facts(facts)
      @metadata[:stores_queried] << :fact_db unless @metadata[:stores_queried].include?(:fact_db)
    end

    # Add memories from HTM
    def add_memories(memories)
      return if memories.nil? || memories.empty?

      @memories += normalize_memories(memories)
      @metadata[:stores_queried] << :htm unless @metadata[:stores_queried].include?(:htm)
    end

    # Resolve and cache entities mentioned in facts/memories
    def resolve_entities(fact_db)
      entity_ids = collect_entity_ids

      entity_ids.each do |id|
        next if @entities[id]

        entity = resolve_entity(fact_db, id)
        @entities[id] = entity if entity
      end
    end

    # Check if results are empty
    def empty?
      @facts.empty? && @memories.empty?
    end

    # Get all items (facts + memories) for comparison operations
    def items
      @facts.map { |f| normalize_for_comparison(f) } +
        @memories.map { |m| normalize_for_comparison(m) }
    end

    # Convert to hash for JSON serialization
    def to_h
      {
        query: @query,
        facts: @facts,
        memories: @memories,
        entities: @entities,
        metadata: @metadata
      }
    end

    # Iterate over all facts
    def each_fact(&block)
      @facts.each(&block)
    end

    # Iterate over all memories
    def each_memory(&block)
      @memories.each(&block)
    end

    # Iterate over all entities
    def each_entity(&block)
      @entities.values.each(&block)
    end

    private

    def normalize_facts(facts)
      facts.map do |fact|
        if fact.is_a?(Hash)
          fact
        elsif fact.respond_to?(:as_json)
          fact.as_json
        else
          {
            id: fact.id,
            fact_text: fact.fact_text,
            valid_at: fact.valid_at,
            invalid_at: fact.invalid_at,
            status: fact.status,
            confidence: fact.respond_to?(:confidence) ? fact.confidence : nil,
            entity_mentions: extract_mentions(fact)
          }
        end
      end
    end

    def normalize_memories(memories)
      memories.map do |memory|
        if memory.is_a?(Hash)
          memory
        elsif memory.respond_to?(:as_json)
          memory.as_json
        else
          {
            id: memory.respond_to?(:id) ? memory.id : memory.object_id,
            content: memory.respond_to?(:content) ? memory.content : memory.to_s,
            type: memory.respond_to?(:node_type) ? memory.node_type : :unknown,
            importance: memory.respond_to?(:importance) ? memory.importance : nil,
            robot_name: memory.respond_to?(:robot_name) ? memory.robot_name : nil,
            created_at: memory.respond_to?(:created_at) ? memory.created_at : nil
          }
        end
      end
    end

    def extract_mentions(fact)
      return [] unless fact.respond_to?(:entity_mentions)

      fact.entity_mentions.map do |mention|
        {
          entity_id: mention.entity_id,
          role: mention.mention_role
        }
      end
    end

    def collect_entity_ids
      ids = Set.new

      @facts.each do |fact|
        mentions = fact[:entity_mentions] || []
        mentions.each { |m| ids << m[:entity_id] }
      end

      ids.to_a
    end

    def resolve_entity(fact_db, id)
      if fact_db.respond_to?(:entity_service)
        fact_db.entity_service.find(id)
      elsif fact_db.respond_to?(:find_entity)
        fact_db.find_entity(id)
      end
    rescue StandardError
      nil
    end

    def normalize_for_comparison(item)
      # Create a comparable representation
      if item[:fact_text]
        { type: :fact, text: item[:fact_text], valid_at: item[:valid_at] }
      elsif item[:content]
        { type: :memory, text: item[:content], type: item[:type] }
      else
        item
      end
    end
  end
end
