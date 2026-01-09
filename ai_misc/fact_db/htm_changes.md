# Context Graph Analysis: HTM + FactDB Integration

Based on:
- [Context Graph Manifesto](./context_graph_manifesto.md) by Daniel Davis (@TrustSpooky)
- [Building the Event Clock](./building_the_event_clock.md) by Kirk Marple (@KirkMarple)
- [HTM Project](https://madbomber.github.io/htm) - Hierarchical Temporal Memory
- [FactDB Project](https://madbomber.github.io/fact_db) - Event Clock Implementation

---

## The Two Clocks Problem

Kirk Marple articulates the core insight:

> "Every system has a **state clock**—what's true right now—and an **event clock**—what happened, in what order, with what reasoning. We've built elaborate infrastructure for the state clock. The event clock barely exists."

Your two projects map directly to this:

| Clock | Project | Purpose |
|-------|---------|---------|
| **State Clock** | HTM | What's true now for this robot's working memory |
| **Event Clock** | FactDB | What happened, when, with temporal validity |

Together, they form a complete AI memory infrastructure.

---

## How the Projects Connect

```
┌─────────────────────────────────────────────────────────────────┐
│                     CONTEXT GRAPH LAYER                         │
│  (Self-describing, structured output for LLMs)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────────┐
│         HTM             │     │           FactDB                │
│    (State Clock)        │     │        (Event Clock)            │
├─────────────────────────┤     ├─────────────────────────────────┤
│ • Working Memory        │     │ • Content Layer (immutable)     │
│ • Long-term Storage     │     │ • Entity Layer (resolved)       │
│ • Robot-specific context│     │ • Fact Layer (temporal)         │
│ • Token management      │     │ • valid_at / invalid_at         │
│ • Hive Mind sharing     │     │ • Corroboration tracking        │
└─────────────────────────┘     └─────────────────────────────────┘
              │                               │
              └───────────────┬───────────────┘
                              ▼
                    PostgreSQL + pgvector
```

---

## FactDB: The Event Clock Implementation

FactDB already implements the core concepts from Kirk Marple's vision:

| Concept | FactDB Implementation |
|---------|----------------------|
| Three-Layer Model | Content → Entity → Fact |
| Temporal Validity | `valid_at`, `invalid_at` timestamps |
| Fact Status | canonical, superseded, corroborated, synthesized |
| Entity Resolution | Aliases, fuzzy matching, merging |
| Audit Trail | fact_sources linking back to content |
| LLM Extraction | LLMExtractor for automated fact extraction |

### What FactDB Does Well

1. **Temporal assertions as first-class data** - Not just timestamps, but validity windows
2. **Fact lifecycle management** - canonical → corroborated → superseded
3. **Entity resolution** - "Paula", "P. Chen", "Paula Chen" → single entity
4. **Source provenance** - Every fact traces back to content evidence

---

## Current HTM State vs. Context Graph Vision

| HTM Feature | Current State | Context Graph Enhancement |
|-------------|---------------|---------------------------|
| Knowledge Graph | Nodes + relationships + tags | Triple-based representation (Subject → Predicate → Object) |
| RAG Retrieval | Vector + fulltext + hybrid | Add graph traversal, clustering, temporal analytics |
| Memory Types | 6 fixed types (fact, context, code...) | Ontology-driven, extensible type system |
| Temporal | TimescaleDB time-range queries | Temporal reasoning (freshness ≠ accuracy) |
| Hive Mind | Shared storage, robot tracking | Self-describing, interoperable knowledge exchange |

---

## Key Opportunities

### 1. Self-Describing Memory Store (Step 6)

HTM could expose metadata about itself:

```ruby
htm.describe_schema  # Returns what memory types exist, their relationships
htm.describe_contents("architecture")  # What do I know about this topic?
```

An LLM could then dynamically figure out how to query without hardcoded logic.

### 2. Structure as Information

The manifesto found that Cypher/RDF format improved LLM responses. HTM's `create_context()` could output memories in a structured graph format rather than just text chunks:

```
(CodeHelper)-[:DECIDED]->(PostgreSQL {reason: "durability", when: "2024-10-24"})
(PostgreSQL)-[:ENABLES]->(VectorSearch)
```

### 3. Temporal Reasoning

HTM already has TimescaleDB. The manifesto emphasizes: *"Freshness ≠ accuracy. Just because data is old doesn't mean it's not valid."*

HTM could track:
- How many times a fact has been corroborated
- Whether newer data contradicts older data
- "Ground truth" facts that remain constant

### 4. The Progression Path

HTM is currently at **Step 2-3** (RAG + basic graph). The path forward:

| Step | What HTM Could Add |
|------|-------------------|
| 4. OntologyRAG | Formal ontology for memory types, relationships |
| 5. Specialized retrieval | Different strategies for facts vs decisions vs code |
| 6. Self-describing | Memory system describes its own structure to LLMs |
| 7. Dynamic retrieval | LLM generates its own queries based on schema |
| 8. Autonomous learning | HTM learns from robot interactions, adjusts retrieval |

### 5. Hive Mind as Context Graph

The multi-robot feature maps directly to the interoperability vision. Each robot could:
- Publish memories with semantic annotations
- Query other robots' knowledge graphs
- Merge knowledge with conflict resolution

---

## Recommendation: Make HTM Self-Describing

The most impactful addition would be making HTM **self-describing**:

```ruby
# Robot asks: "What do you know about databases?"
htm.introspect("databases")
# => {
#   schema: { nodes: [:decision, :fact], relationships: [:led_to, :contradicts] },
#   coverage: { decisions: 5, facts: 12, timespan: "2024-01-01..2024-10-24" },
#   suggested_queries: ["architecture decisions", "PostgreSQL vs alternatives"]
# }
```

This transforms HTM from a passive store into an **active participant** in the retrieval process - exactly what the manifesto describes as the path to autonomous learning.

---

## Implementation Priority

1. **Phase 1: Introspection API**
   - `htm.describe_schema` - Returns available memory types, relationship types, tag categories
   - `htm.describe_contents(topic)` - Returns coverage statistics for a topic
   - `htm.suggest_queries(topic)` - Returns suggested queries based on what's stored

2. **Phase 2: Structured Context Output**
   - `htm.create_context(format: :cypher)` - Output memories in Cypher-like graph format
   - `htm.create_context(format: :triples)` - Output as Subject-Predicate-Object triples
   - Preserve semantic structure so LLMs can leverage it

3. **Phase 3: Temporal Intelligence**
   - Track corroboration count for facts
   - Detect contradictions between memories
   - Implement "ground truth" markers for immutable facts
   - Add recency vs. accuracy scoring

4. **Phase 4: Dynamic Retrieval**
   - Allow LLMs to generate their own queries based on schema
   - Implement query planning based on memory structure
   - Support ad-hoc relationship traversal

5. **Phase 5: Autonomous Learning Loop**
   - Track which memories were useful in responses
   - Adjust importance scores based on usage patterns
   - Learn optimal retrieval strategies per robot/context

---

## Key Insight from the Manifesto

> "Providing context in structured formats like Cypher or RDF improved responses despite the token overhead. Why? Because the structure itself carries information."

HTM should not just store memories - it should present them in a way that encodes semantic meaning through structure. The format *is* information.

---

## FactDB Enhancement Opportunities

### 1. Apply Context Graph Principles

FactDB is well-positioned but could benefit from:

| Current | Enhancement |
|---------|-------------|
| JSON/text output | Structured graph output (Cypher, RDF, triples) |
| Query by parameters | Self-describing schema for LLM discovery |
| Fixed fact types | Ontology-driven extensible types |

### 2. Self-Describing Event Clock

```ruby
# FactDB could expose its structure to LLMs
clock.introspect("Paula Chen")
# => {
#   entity: { type: :person, aliases: ["Paula", "P. Chen"] },
#   fact_coverage: {
#     canonical: 5,
#     superseded: 2,
#     timespan: "2024-01-10..present"
#   },
#   relationships: [:works_at, :has_role, :reports_to],
#   suggested_queries: ["current role", "employment history", "team members"]
# }
```

### 3. Structured Context Output

The manifesto found that graph formats improve LLM responses:

```ruby
clock.facts_for_context(entity: paula.id, format: :triples)
# => [
#   ["Paula Chen", "works_at", "Microsoft"],
#   ["Paula Chen", "has_role", "Principal Engineer"],
#   ["Paula Chen", "valid_from", "2024-01-10"],
#   ["works_at", "supersedes", "Google (2020-2024)"]
# ]
```

---

## HTM + FactDB Integration Vision

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    AI Agent / Robot                          │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                 Context Graph Layer                          │
│  • Self-describing schema                                    │
│  • Structured output (triples/Cypher)                        │
│  • Dynamic retrieval strategies                              │
└──────────────────────────────────────────────────────────────┘
              │                               │
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────┐
│         HTM             │◄───►│         FactDB              │
│    Working Memory       │     │      Temporal Facts         │
├─────────────────────────┤     ├─────────────────────────────┤
│ "What's active now"     │     │ "What's historically true"  │
│                         │     │                             │
│ • Current conversation  │     │ • Paula works at Microsoft  │
│ • Recent decisions      │     │   (valid_at: 2024-01-10)    │
│ • Active preferences    │     │ • Paula worked at Google    │
│ • Token budget mgmt     │     │   (2020-01-15 to 2024-01-09)|
└─────────────────────────┘     └─────────────────────────────┘
```

### Integration Points

1. **HTM pulls from FactDB for grounding**
   ```ruby
   # Robot needs context about Paula
   facts = clock.facts_at(Date.today, entity: "Paula Chen")
   htm.add_context(facts, type: :fact, source: :fact_db)
   ```

2. **HTM writes decisions back to FactDB**
   ```ruby
   # Robot makes a decision worth remembering
   htm.add_node("decision_001", "We chose PostgreSQL", type: :decision)
   clock.create_fact("Team chose PostgreSQL for HTM storage",
     valid_at: Date.today,
     source: htm.robot_name
   )
   ```

3. **Shared Entity Resolution**
   ```ruby
   # Both systems use the same entity layer
   entity = FactDB::EntityService.resolve("Paula Chen")
   htm.add_node("paula_context", content, entity_id: entity.id)
   ```

4. **Unified Temporal Queries**
   ```ruby
   # "What did we know about Paula on March 1st?"
   # FactDB provides the facts, HTM provides the robot's context
   facts = clock.facts_at(Date.parse("2024-03-01"), entity: paula.id)
   memories = htm.recall(timeframe: "2024-03-01", topic: "Paula")
   ```

---

## Unified Roadmap

### Phase 1: Shared Foundation
- [ ] Unified PostgreSQL schema (both use pgvector)
- [ ] Shared Entity model between HTM and FactDB
- [ ] Common embedding service (RubyLLM/Ollama)

### Phase 2: Self-Describing Layer
- [ ] `introspect()` API for both HTM and FactDB
- [ ] Schema discovery for LLMs
- [ ] Structured output formats (triples, Cypher)

### Phase 3: Cross-System Integration
- [ ] HTM pulls facts from FactDB for grounding
- [ ] HTM writes significant memories to FactDB as facts
- [ ] Shared entity resolution

### Phase 4: Context Graph Unification
- [ ] Single query interface spanning both systems
- [ ] Unified temporal queries ("what was true then")
- [ ] Combined graph visualization

### Phase 5: Autonomous Learning
- [ ] Track which facts/memories were useful
- [ ] Adjust importance scores based on usage
- [ ] Learn optimal retrieval strategies

---

## Key Insights

### From the Context Graph Manifesto (Daniel Davis)

> "Providing context in structured formats like Cypher or RDF improved responses despite the token overhead. Why? Because the structure itself carries information."

**Application:** Both HTM and FactDB should output context in structured graph formats, not just text.

### From Building the Event Clock (Kirk Marple)

> "Facts need to be first-class entities, not just derived metadata... The event clock becomes queryable data, not reconstructed reasoning."

**Application:** FactDB is already doing this. HTM should treat its `:decision` and `:fact` memory types with similar rigor.

### The Synthesis

You have the two clocks:
- **FactDB** = Event Clock (what happened, when, with evidence)
- **HTM** = State Clock (what's true now for this robot)

Add the Context Graph layer on top:
- Self-describing schemas
- Structured output formats
- Dynamic retrieval strategies

And you have a complete AI memory infrastructure that can:
1. Remember what happened (FactDB)
2. Know what's relevant now (HTM)
3. Present context in a format that maximizes LLM performance (Context Graph)

---

*Analysis based on Context Graph Manifesto (Dec 31, 2025), Building the Event Clock (Dec 28, 2025), HTM, and FactDB project documentation.*
