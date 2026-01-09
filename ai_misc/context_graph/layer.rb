# frozen_string_literal: true

module ContextGraph
  # The main Context Graph Layer class.
  # Provides a unified interface for querying multiple data stores
  # and transforming results into LLM-friendly formats.
  #
  # @example Basic usage
  #   layer = ContextGraph::Layer.new(
  #     stores: {
  #       fact_db: my_fact_db_clock,
  #       htm: my_htm_instance
  #     }
  #   )
  #
  #   # Introspect what the layer knows
  #   schema = layer.introspect
  #
  #   # Query with structured output
  #   result = layer.query("Paula Chen", format: :triples)
  #
  class Layer
    attr_reader :stores, :options

    # Default output format
    DEFAULT_FORMAT = :triples

    # Available output formats
    FORMATS = %i[triples cypher text prolog json].freeze

    # Available retrieval strategies
    STRATEGIES = %i[auto semantic fulltext graph temporal hybrid].freeze

    def initialize(stores: {}, **options)
      @stores = stores
      @options = options
      @transformers = build_transformers
      validate_stores!
    end

    # Introspect the schema - what does the layer know about?
    #
    # @param topic [String, nil] Optional topic to introspect specifically
    # @return [Hash] Schema information or topic-specific coverage
    def introspect(topic = nil)
      if topic
        introspect_topic(topic)
      else
        introspect_schema
      end
    end

    # Query across all stores with unified interface
    #
    # @param query_text [String] Natural language or structured query
    # @param format [Symbol] Output format (:triples, :cypher, :text, :prolog, :json)
    # @param strategy [Symbol] Retrieval strategy (:auto, :semantic, :fulltext, :graph, :temporal, :hybrid)
    # @param at [Date, String, nil] Optional point-in-time for temporal queries
    # @return [QueryResult] Transformed results
    def query(query_text, format: DEFAULT_FORMAT, strategy: :auto, at: nil, **options)
      validate_format!(format)

      # Build query context
      context = {
        query: query_text,
        strategy: strategy,
        at: parse_date(at),
        options: options
      }

      # Retrieve from stores
      results = retrieve(context)

      # Transform to requested format
      transform(results, format)
    end

    # Temporal query helper - query at a specific point in time
    #
    # @param date [Date, String] The point in time
    # @return [TemporalQuery] A scoped query builder
    def at(date)
      TemporalQuery.new(self, parse_date(date))
    end

    # Compare what changed between two dates
    #
    # @param topic [String] What to compare
    # @param from [Date, String] Start date
    # @param to [Date, String] End date
    # @return [Hash] Differences
    def diff(topic, from:, to:)
      from_results = query(topic, at: from, format: :json)
      to_results = query(topic, at: to, format: :json)

      {
        topic: topic,
        from: parse_date(from),
        to: parse_date(to),
        added: to_results.items - from_results.items,
        removed: from_results.items - to_results.items,
        unchanged: from_results.items & to_results.items
      }
    end

    # Suggest queries based on what's stored
    #
    # @param topic [String] Topic to get suggestions for
    # @return [Array<String>] Suggested queries
    def suggest_queries(topic)
      entity = resolve_entity(topic)
      return [] unless entity

      suggestions = []
      entity_type = entity.is_a?(Hash) ? entity[:entity_type] || entity[:type] : entity.entity_type

      suggestions << "current status" if entity_type == :person

      # Check relationships
      relationships = relationships_for(entity)
      suggestions << "employment history" if relationships.include?(:works_at) || relationships.include?(:worked_at)
      suggestions << "team members" if relationships.include?(:works_with)
      suggestions << "reporting chain" if relationships.include?(:reports_to)

      # Check memory coverage
      memory_stats = memory_stats_for(entity)
      suggestions << "recent decisions" if memory_stats[:decisions]&.positive?

      # Check fact coverage
      fact_stats = fact_stats_for(entity)
      suggestions << "timeline" if fact_stats[:canonical]&.positive?

      suggestions
    end

    # Suggest retrieval strategies for a query
    #
    # @param query_text [String] The query
    # @return [Array<Hash>] Strategy options with descriptions
    def suggest_strategies(query_text)
      strategies = []

      # Check for temporal keywords
      if query_text.match?(/\b(yesterday|last\s+week|last\s+month|ago|since|before|after|between)\b/i)
        strategies << { strategy: :temporal, description: "Filter by date range" }
      end

      # Check for semantic intent
      if query_text.match?(/\b(about|related|similar|like)\b/i)
        strategies << { strategy: :semantic, description: "Search by semantic similarity" }
      end

      # Check for entity focus
      if query_text.match?(/\b(who|what|where)\b/i)
        strategies << { strategy: :graph, description: "Traverse from entity node" }
      end

      # Default: hybrid
      strategies << { strategy: :hybrid, description: "Combine multiple strategies" }

      strategies
    end

    # Register a store dynamically
    #
    # @param name [Symbol] Store name
    # @param store [Object] Store instance
    def register_store(name, store)
      @stores[name.to_sym] = store
    end

    # Get a specific store
    #
    # @param name [Symbol] Store name
    # @return [Object] The store
    def store(name)
      @stores[name.to_sym] || raise(StoreNotFoundError, "Store not found: #{name}")
    end

    private

    def validate_stores!
      # Stores are optional - layer can work with mock data
    end

    def validate_format!(format)
      return if FORMATS.include?(format)

      raise ArgumentError, "Unknown format: #{format}. Available: #{FORMATS.join(', ')}"
    end

    def parse_date(date)
      return nil if date.nil?
      return date if date.is_a?(Date)

      Date.parse(date.to_s)
    rescue ArgumentError
      nil
    end

    def build_transformers
      {
        triples: Transformers::TripleTransformer.new,
        cypher: Transformers::CypherTransformer.new,
        text: Transformers::TextTransformer.new,
        prolog: Transformers::PrologTransformer.new,
        json: Transformers::Base.new # JSON is pass-through
      }
    end

    def introspect_schema
      schema = {
        stores: @stores.keys,
        capabilities: collect_capabilities,
        entity_types: collect_entity_types,
        relationship_types: collect_relationship_types,
        memory_types: collect_memory_types,
        fact_statuses: %i[canonical superseded corroborated synthesized]
      }

      schema[:statistics] = collect_statistics if @options[:include_stats]

      schema
    end

    def introspect_topic(topic)
      entity = resolve_entity(topic)
      return nil unless entity

      {
        entity: entity_info(entity),
        coverage: {
          facts: fact_stats_for(entity),
          memories: memory_stats_for(entity),
          timespan: timespan_for(entity)
        },
        relationships: relationships_for(entity),
        suggested_queries: suggest_queries(topic)
      }
    end

    def collect_capabilities
      capabilities = [:introspection]

      capabilities << :temporal_query if @stores[:fact_db]
      capabilities << :semantic_search if @stores.values.any? { |s| s.respond_to?(:semantic_search) }
      capabilities << :entity_resolution if @stores[:fact_db]
      capabilities << :working_memory if @stores[:htm]

      capabilities
    end

    def collect_entity_types
      return [] unless @stores[:fact_db]

      if @stores[:fact_db].respond_to?(:entity_types)
        @stores[:fact_db].entity_types
      else
        %i[person organization place product event]
      end
    end

    def collect_relationship_types
      types = []

      if @stores[:fact_db]&.respond_to?(:relationship_types)
        types += @stores[:fact_db].relationship_types
      end

      if @stores[:htm]&.respond_to?(:relationship_types)
        types += @stores[:htm].relationship_types
      end

      types.uniq
    end

    def collect_memory_types
      return [] unless @stores[:htm]

      if @stores[:htm].respond_to?(:memory_types)
        @stores[:htm].memory_types
      else
        %i[fact context code preference decision question]
      end
    end

    def collect_statistics
      stats = {}

      if @stores[:fact_db]&.respond_to?(:statistics)
        stats[:fact_db] = @stores[:fact_db].statistics
      end

      if @stores[:htm]&.respond_to?(:memory_stats)
        stats[:htm] = @stores[:htm].memory_stats
      end

      stats
    end

    def resolve_entity(topic)
      return nil unless @stores[:fact_db]

      if @stores[:fact_db].respond_to?(:entity_service)
        @stores[:fact_db].entity_service.resolve(topic)
      elsif @stores[:fact_db].respond_to?(:resolve_entity)
        @stores[:fact_db].resolve_entity(topic)
      else
        # Mock entity for testing
        { id: topic.hash.abs, canonical_name: topic, type: :unknown }
      end
    end

    def entity_info(entity)
      if entity.is_a?(Hash)
        entity
      elsif entity.respond_to?(:as_json)
        entity.as_json
      else
        { id: entity.id, canonical_name: entity.canonical_name, type: entity.entity_type }
      end
    end

    def fact_stats_for(entity)
      return {} unless @stores[:fact_db]

      entity_id = entity.is_a?(Hash) ? entity[:id] : entity.id

      if @stores[:fact_db].respond_to?(:fact_stats)
        @stores[:fact_db].fact_stats(entity_id)
      else
        { canonical: 0, superseded: 0, corroborated: 0 }
      end
    end

    def memory_stats_for(entity)
      return {} unless @stores[:htm]

      entity_id = entity.is_a?(Hash) ? entity[:id] : entity.id

      if @stores[:htm].respond_to?(:memory_stats)
        @stores[:htm].memory_stats(entity: entity_id)
      else
        { decisions: 0, context: 0 }
      end
    end

    def timespan_for(entity)
      return nil unless @stores[:fact_db]

      entity_id = entity.is_a?(Hash) ? entity[:id] : entity.id

      if @stores[:fact_db].respond_to?(:timespan_for)
        @stores[:fact_db].timespan_for(entity_id)
      end
    end

    def relationships_for(entity)
      return [] unless @stores[:fact_db]

      entity_id = entity.is_a?(Hash) ? entity[:id] : entity.id

      if @stores[:fact_db].respond_to?(:relationship_types_for)
        @stores[:fact_db].relationship_types_for(entity_id)
      else
        []
      end
    end

    def retrieve(context)
      results = QueryResult.new(query: context[:query])

      # Retrieve from FactDB
      if @stores[:fact_db]
        facts = retrieve_from_fact_db(context)
        results.add_facts(facts)
      end

      # Retrieve from HTM
      if @stores[:htm]
        memories = retrieve_from_htm(context)
        results.add_memories(memories)
      end

      # Resolve entities mentioned in results
      results.resolve_entities(@stores[:fact_db]) if @stores[:fact_db]

      results
    end

    def retrieve_from_fact_db(context)
      store = @stores[:fact_db]

      if context[:at]
        # Temporal query
        if store.respond_to?(:facts_at)
          store.facts_at(context[:at], query: context[:query])
        elsif store.respond_to?(:query_facts)
          store.query_facts(context[:query], at: context[:at])
        else
          []
        end
      else
        # Current facts
        if store.respond_to?(:query_facts)
          store.query_facts(context[:query])
        elsif store.respond_to?(:search_facts)
          store.search_facts(context[:query])
        else
          []
        end
      end
    end

    def retrieve_from_htm(context)
      store = @stores[:htm]

      if store.respond_to?(:recall)
        store.recall(
          topic: context[:query],
          timeframe: context[:at] ? context[:at].to_s : nil
        )
      elsif store.respond_to?(:search)
        store.search(context[:query])
      else
        []
      end
    end

    def transform(results, format)
      transformer = @transformers[format]
      raise TransformError, "No transformer for format: #{format}" unless transformer

      transformer.transform(results)
    end
  end
end
