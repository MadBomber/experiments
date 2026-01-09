# What a Context Graph Layer Looks Like

Based on the [Context Graph Manifesto](./context_graph_manifesto.md) and [Building the Event Clock](./building_the_event_clock.md).

---

## Overview

A Context Graph Layer is an **abstraction layer** that sits between your data stores (HTM, FactDB) and the LLM/Agent. Its job is to:

1. **Describe itself** to LLMs (self-describing schema)
2. **Transform data** into structured formats that carry semantic meaning
3. **Orchestrate retrieval** across multiple underlying stores
4. **Adapt dynamically** to what the LLM needs

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        LLM / Agent                              │
│  "What do you know about Paula's career history?"               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CONTEXT GRAPH LAYER                          │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ Introspect  │  │  Transform  │  │    Retrieve & Merge     │ │
│  │   Schema    │  │   Output    │  │    Across Stores        │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│                                                                 │
│  Input:  Natural language query                                 │
│  Output: Structured graph context (triples, Cypher, etc.)       │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐
        │   HTM    │    │  FactDB  │    │  Other   │
        │  (State) │    │ (Events) │    │  Stores  │
        └──────────┘    └──────────┘    └──────────┘
```

---

## Core Components

### 1. Schema Introspection API

The layer describes what it knows:

```ruby
# Global introspection
context_graph.introspect
# => {
#   stores: [:htm, :fact_db],
#   entity_types: [:person, :organization, :place, :product],
#   relationship_types: [:works_at, :reports_to, :decided, :supersedes],
#   fact_statuses: [:canonical, :superseded, :corroborated],
#   memory_types: [:decision, :preference, :context, :code],
#   capabilities: [:temporal_query, :entity_resolution, :semantic_search]
# }

# Topic-specific introspection
context_graph.introspect("Paula Chen")
# => {
#   entity: { id: 123, type: :person, canonical_name: "Paula Chen" },
#   coverage: {
#     facts: { canonical: 5, superseded: 2 },
#     memories: { decisions: 3, context: 12 },
#     timespan: "2020-01-15..present"
#   },
#   relationships: [:works_at, :has_role, :worked_with],
#   suggested_queries: [
#     "current role",
#     "employment history",
#     "team members",
#     "recent decisions involving Paula"
#   ]
# }
```

### 2. Structured Output Transformer

The key insight from the manifesto: **structure carries information**. The layer transforms data into formats that encode semantic meaning:

#### Triple Format (Subject → Predicate → Object)

```ruby
context_graph.query("Paula Chen career", format: :triples)
# => [
#   ["Paula Chen", "type", "Person"],
#   ["Paula Chen", "works_at", "Microsoft"],
#   ["Paula Chen", "has_role", "Principal Engineer"],
#   ["Paula Chen", "works_at.valid_from", "2024-01-10"],
#   ["Paula Chen", "previously_worked_at", "Google"],
#   ["Google", "employment.valid_from", "2020-01-15"],
#   ["Google", "employment.valid_until", "2024-01-09"],
#   ["Paula Chen", "was_promoted_to", "Senior Engineer"],
#   ["Senior Engineer", "promotion.valid_at", "2022-06-01"],
#   ["Senior Engineer", "promotion.at_org", "Google"]
# ]
```

#### Cypher-like Format

```ruby
context_graph.query("Paula Chen career", format: :cypher)
# =>
# (paula:Person {name: "Paula Chen"})
# (microsoft:Organization {name: "Microsoft"})
# (google:Organization {name: "Google"})
# (paula)-[:WORKS_AT {since: "2024-01-10", role: "Principal Engineer"}]->(microsoft)
# (paula)-[:WORKED_AT {from: "2020-01-15", until: "2024-01-09"}]->(google)
# (paula)-[:PROMOTED_TO {at: "2022-06-01", role: "Senior Engineer", org: "Google"}]->(google)
```

#### RDF/Turtle Format

```ruby
context_graph.query("Paula Chen career", format: :turtle)
# =>
# @prefix ex: <http://example.org/> .
# @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
#
# ex:PaulaChen a ex:Person ;
#     ex:worksAt ex:Microsoft ;
#     ex:hasRole "Principal Engineer" ;
#     ex:employmentStart "2024-01-10"^^xsd:date .
```

### 3. Unified Query Interface

```ruby
# Natural language query that spans both stores
context_graph.query("What decisions did we make about Paula's team last quarter?")

# Internally:
# 1. Resolves "Paula" → Entity
# 2. Queries FactDB for facts about Paula's team
# 3. Queries HTM for decisions mentioning Paula
# 4. Merges and ranks by relevance
# 5. Outputs in structured format

# Temporal queries
context_graph.at("2023-06-15").query("Paula's role")
# => Queries FactDB with valid_at <= 2023-06-15 AND (invalid_at IS NULL OR invalid_at > 2023-06-15)

# Comparison queries
context_graph.diff("Paula's role", from: "2023-01-01", to: "2024-01-01")
# => Shows what changed between those dates
```

### 4. Dynamic Retrieval Strategy

```ruby
# The layer chooses retrieval strategy based on query type
context_graph.query("Paula Chen", strategy: :auto)

# For entity queries → Graph traversal from entity node
# For temporal queries → FactDB temporal filtering
# For semantic queries → Vector similarity search
# For keyword queries → Full-text search
# For complex queries → Hybrid approach

# Or the LLM can ask for strategy options
context_graph.suggest_strategies("What happened in the auth system last week?")
# => [
#   { strategy: :temporal, description: "Filter by date range" },
#   { strategy: :semantic, description: "Search for auth-related content" },
#   { strategy: :graph, description: "Traverse from 'auth system' entity" }
# ]
```

---

## Ruby Implementation Sketch

```ruby
module ContextGraph
  class Layer
    def initialize(stores:)
      @stores = stores  # { htm: HTM.new(...), fact_db: FactDB::Clock.new(...) }
    end

    # Self-describing schema
    def introspect(topic = nil)
      if topic
        introspect_topic(topic)
      else
        introspect_schema
      end
    end

    # Unified query with format transformation
    def query(query_text, format: :triples, strategy: :auto)
      # 1. Parse query intent
      intent = parse_intent(query_text)

      # 2. Choose retrieval strategy
      strategy = choose_strategy(intent) if strategy == :auto

      # 3. Query underlying stores
      results = retrieve(intent, strategy)

      # 4. Merge and deduplicate
      merged = merge_results(results)

      # 5. Transform to output format
      transform(merged, format)
    end

    # Temporal query helper
    def at(date)
      TemporalQuery.new(self, date)
    end

    # Suggest queries based on what's stored
    def suggest_queries(topic)
      coverage = introspect(topic)
      generate_suggestions(coverage)
    end

    private

    def introspect_schema
      {
        stores: @stores.keys,
        entity_types: @stores[:fact_db].entity_types,
        memory_types: @stores[:htm].memory_types,
        relationship_types: collect_relationship_types,
        capabilities: [:temporal_query, :entity_resolution, :semantic_search]
      }
    end

    def introspect_topic(topic)
      entity = resolve_entity(topic)
      return nil unless entity

      {
        entity: entity.as_json,
        coverage: {
          facts: @stores[:fact_db].fact_stats(entity.id),
          memories: @stores[:htm].memory_stats(entity: entity.id)
        },
        relationships: @stores[:fact_db].relationship_types_for(entity.id),
        suggested_queries: suggest_queries(topic)
      }
    end

    def transform(results, format)
      case format
      when :triples
        TripleTransformer.transform(results)
      when :cypher
        CypherTransformer.transform(results)
      when :turtle, :rdf
        RDFTransformer.transform(results)
      when :text
        TextTransformer.transform(results)
      else
        results
      end
    end
  end
end
```

---

## Output Transformers

### Triple Transformer

```ruby
module ContextGraph
  class TripleTransformer
    def self.transform(results)
      triples = []

      results[:entities].each do |entity|
        triples << [entity.canonical_name, "type", entity.entity_type]

        entity.aliases.each do |aka|
          triples << [entity.canonical_name, "also_known_as", aka]
        end
      end

      results[:facts].each do |fact|
        subject = fact.subject_entity.canonical_name

        # Main assertion
        triples << [subject, fact.predicate, fact.object_value]

        # Temporal metadata
        triples << [subject, "#{fact.predicate}.valid_from", fact.valid_at.to_s]
        if fact.invalid_at
          triples << [subject, "#{fact.predicate}.valid_until", fact.invalid_at.to_s]
        end

        # Status
        triples << [subject, "#{fact.predicate}.status", fact.status]
      end

      results[:memories].each do |memory|
        triples << [memory.robot_name, "remembered", memory.content]
        triples << [memory.content, "type", memory.node_type]
        triples << [memory.content, "importance", memory.importance.to_s]
      end

      triples
    end
  end
end
```

### Cypher Transformer

```ruby
module ContextGraph
  class CypherTransformer
    def self.transform(results)
      lines = []

      # Define nodes
      results[:entities].each do |entity|
        var = entity.canonical_name.downcase.gsub(/\s+/, '_')
        lines << "(#{var}:#{entity.entity_type.capitalize} {name: \"#{entity.canonical_name}\"})"
      end

      # Define relationships
      results[:facts].each do |fact|
        subject_var = fact.subject_entity.canonical_name.downcase.gsub(/\s+/, '_')
        object_var = fact.object_entity&.canonical_name&.downcase&.gsub(/\s+/, '_')

        props = []
        props << "since: \"#{fact.valid_at}\"" if fact.valid_at
        props << "until: \"#{fact.invalid_at}\"" if fact.invalid_at
        props << "status: \"#{fact.status}\""

        prop_str = props.any? ? " {#{props.join(', ')}}" : ""

        if object_var
          lines << "(#{subject_var})-[:#{fact.predicate.upcase}#{prop_str}]->(#{object_var})"
        else
          lines << "(#{subject_var})-[:#{fact.predicate.upcase}#{prop_str}]->(\"#{fact.object_value}\")"
        end
      end

      lines.join("\n")
    end
  end
end
```

---

## Why This Matters for LLMs

The manifesto's key finding:

> "Providing context in structured formats like Cypher or RDF improved responses despite the token overhead."

When an LLM receives:

```
Paula works at Microsoft as a Principal Engineer since January 2024.
She previously worked at Google from 2020 to 2024.
```

vs:

```
(paula:Person)-[:WORKS_AT {since: "2024-01-10", role: "Principal Engineer"}]->(microsoft:Org)
(paula)-[:WORKED_AT {from: "2020-01-15", until: "2024-01-09"}]->(google:Org)
```

The second format **encodes semantic structure** that the LLM can leverage:
- What's a node vs. a relationship
- What's a property vs. an entity
- Temporal validity is explicit
- Relationships are typed

---

## Integration with HTM + FactDB

```ruby
# Initialize the Context Graph Layer
context_graph = ContextGraph::Layer.new(
  stores: {
    htm: HTM.new(robot_name: "Assistant"),
    fact_db: FactDB::Clock.new
  }
)

# LLM asks what the system knows
schema = context_graph.introspect
# LLM now knows: entity types, memory types, capabilities

# LLM queries for specific context
context = context_graph.query(
  "Paula Chen's career history and any decisions we made about her team",
  format: :cypher
)
# Returns structured graph data spanning both stores

# LLM can also ask for temporal comparisons
diff = context_graph.diff("Paula's role", from: "2023-01-01", to: "2024-06-01")
# Returns what changed over that period
```

---

## Summary

The Context Graph Layer is the missing piece that:

1. **Unifies** HTM (state clock) and FactDB (event clock)
2. **Self-describes** its schema so LLMs can discover capabilities
3. **Transforms** raw data into structured formats (triples, Cypher, RDF)
4. **Orchestrates** retrieval across multiple stores
5. **Enables** the 8-step progression from RAG to autonomous learning

Without it, HTM and FactDB are separate stores. With it, they become a coherent **organizational memory** that LLMs can reason over effectively.

---

---

## Related: Prolog and Logic Programming

Context Graphs share deep similarities with Prolog. The triple representation maps directly to Prolog facts, and Prolog's inference rules could enhance the Context Graph Layer with automatic derivation of new facts.

See [Prolog Comparison](./docs/architecture/prolog_comparison.md) for a detailed analysis of:
- How triples map to Prolog facts
- Using Prolog rules for inference (colleagues, hierarchies)
- Event Calculus for temporal reasoning
- Ruby Prolog integration options

The Context Graph Layer can be seen as: **Prolog + Temporal Logic + LLM-friendly output formats**

---

*Based on Context Graph Manifesto (Dec 31, 2025) and Building the Event Clock (Dec 28, 2025).*
