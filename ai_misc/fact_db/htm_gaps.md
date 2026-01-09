# HTM vs Event Clock: Correspondence Analysis

**Date:** January 8, 2026 (Updated)
**Context:** Analysis comparing the HTM (Hierarchical Temporal Memory) project against concepts from Kirk Marple's "Building the Event Clock" article.

---

## Conceptual Equivalence

A key insight: HTM and Event Clock use different terminology for the same concepts.

| Event Clock Term | HTM Term | Equivalence |
|------------------|----------|-------------|
| **Fact** | **Proposition/Node** | Same concept: temporal assertions about the world |
| **`validAt`** | **`created_at`** | When the proposition became true (not when the row was inserted) |
| **`invalidAt`** | **`deleted_at`** | When the proposition stopped being true (null = still valid) |

**Important:** HTM's `created_at` is semantically `valid_at`—it represents *when the proposition became true*, not *when the database record was created*. This is a documentation/semantic choice, not a structural limitation.

---

## Strong Alignments

| Event Clock Concept | HTM Implementation | Alignment |
|---------------------|-------------------|-----------|
| **Facts with Temporal Validity** | Propositions with `created_at`/`deleted_at` | **Excellent** |
| **Multi-axis Index** | Vector + Full-text + Temporal | **Good** |
| **Subject Categorization** | `tags` table for hierarchical classification | **Good** |
| **Vector Embeddings** | pgvector with 1536-dim embeddings | **Excellent** |
| **Full-text Search** | PostgreSQL FTS with hybrid search | **Excellent** |
| **Audit Trail** | `operations_log` table | **Good** |
| **World Model for Static LLMs** | RAG retrieval + context assembly | **Good** |
| **"Never Forget" Philosophy** | Explicit `forget()` required | **Excellent** |

---

## Remaining Gaps

| Event Clock Concept | HTM Status | Gap Analysis |
|---------------------|------------|--------------|
| **Fact Status** (Canonical, Superseded, Corroborated, Synthesized) | **Missing** | HTM nodes have `type` but no resolution status. Can't mark a fact as superseded by a newer one |
| **Entity Resolution** | **Missing** | No entity table. "Sarah Chen" and "S. Chen" are stored as separate text values with no identity linking |
| **Content vs Facts Separation** | **Partial** | HTM has `type: :fact` but treats all nodes uniformly. No separation of "raw evidence" from "extracted assertions" |
| **Synthesized Facts** | **Missing** | No mechanism to derive "Paula worked at Google 2020-2024" from multiple point-in-time observations |
| **Geospatial Axis** | **Missing** | No location metadata or spatial queries |
| **Entity Mentions on Facts** | **Missing** | Propositions don't link to resolved entities |
| **Knowledge Graph / Relationships** | **Missing** | No relationships table. HTM uses `tags` for subject hierarchy, not graph traversal |

---

## Detailed Comparison

### 1. Temporal Model

**Event Clock's Model:**
```
Fact: "Paula works at Microsoft"
├── validAt: 2024-03-15
├── invalidAt: null (still true)
└── Status: Canonical
```

**HTM's Model:**
```
Proposition: "Paula works at Microsoft"
├── created_at: 2024-03-15  (= when this became true)
├── deleted_at: null        (= still true)
└── type: :fact
```

**Status: Equivalent.** HTM's `created_at` serves as `valid_at` when semantically defined as "when the proposition became true." Adding `deleted_at` completes the temporal validity window.

**Query Examples:**
- "What's Paula's current employer?" → `WHERE deleted_at IS NULL`
- "Where did Paula work in 2022?" → `WHERE created_at <= '2022-12-31' AND (deleted_at > '2022-01-01' OR deleted_at IS NULL)`

### 2. Entity Resolution

**Event Clock's Three Layers:**
```
Content → Entities → Facts
   ↓         ↓         ↓
Raw docs  Resolved   Temporal
          identities assertions
```

**HTM's Model:**
```
Nodes (flat)
  ↓
All content types mixed
```

**Gap:** HTM has no entity layer. If you store propositions about "Sarah Chen", "S. Chen", and "@sarah", they're three unrelated nodes. The Event Clock's identity resolution is prerequisite for reasoning about actors.

### 3. Fact Resolution

**Event Clock:**
- Canonical (authoritative)
- Superseded (replaced by newer)
- Corroborated (confirmed by multiple sources)
- Synthesized (derived from other facts)

**HTM:**
- No equivalent—all nodes have equal status

**Gap:** HTM can't represent that proposition A supersedes proposition B, or that proposition C was synthesized from propositions A and B.

---

## Temporal Query Patterns

Temporal queries fall into three patterns: **past**, **present**, and **future**. HTM handles two of these natively; the third requires special consideration.

### The Three Patterns

| Pattern | Example Query | HTM Support |
|---------|---------------|-------------|
| **Present** | "Does Danny work at Microsoft?" | **Yes** |
| **Past** | "Did Danny work at Microsoft in 1998?" | **Yes** |
| **Future** | "Will Danny work at Microsoft next year?" | **Limited** |

### Present Queries

"What is currently true?"

```sql
SELECT * FROM nodes
WHERE deleted_at IS NULL;
```

```ruby
htm.recall_current(topic: "Danny employment")
```

### Past Queries

"What was true at a specific point in time?"

```sql
SELECT * FROM nodes
WHERE created_at <= '1998-12-31'
AND (deleted_at > '1998-01-01' OR deleted_at IS NULL);
```

```ruby
htm.recall_as_of(topic: "Danny employment", date: Time.parse("1998-06-15"))
```

### Future Queries

"What will be true?" — This is fundamentally different.

**The Asymmetry:**
- **Past and Present** are *memory* — recorded assertions about what was/is true
- **Future** is *prediction* — speculation about what might become true

HTM (and Event Clock) are **memory systems**. They answer "what do we know?" not "what do we expect?"

### Special Case: Planned Future Facts

There is one exception — **scheduled/planned events** that are known to become true:

```ruby
# Danny accepted an offer, starts January 15, 2027
htm.add_node("danny_microsoft_future",
             "Danny will work at Microsoft as Senior Engineer",
             created_at: Time.parse("2027-01-15"),  # Future validity
             type: :fact)
```

This isn't prediction — it's a recorded assertion about a **planned future state**. The `created_at` is set to the future date when the proposition becomes true.

**Query planned future propositions:**

```sql
-- What's planned to become true?
SELECT * FROM nodes
WHERE created_at > NOW()
AND deleted_at IS NULL;

-- What will be true on a specific future date?
SELECT * FROM nodes
WHERE created_at <= '2027-06-01'
AND (deleted_at > '2027-06-01' OR deleted_at IS NULL);
```

### Temporal States

| State | `created_at` | `deleted_at` | Meaning |
|-------|-------------|--------------|---------|
| **Historical** | Past | Past | Was true, no longer true |
| **Current** | Past | NULL | Is true now |
| **Planned** | Future | NULL | Scheduled to become true |
| **Cancelled** | Future | Not NULL | Was planned, now cancelled |

### What HTM Cannot Do

True future prediction ("Will Danny work at Microsoft?") requires:
- Inference from patterns
- Probabilistic reasoning
- External prediction models

This is outside the scope of a memory/fact system. A prediction layer would need to *use* HTM's propositions as input, but prediction itself is not memory.

---

## What HTM Does Well (Event Clock Would Approve)

1. **Temporal Validity** - `created_at`/`deleted_at` model matches `validAt`/`invalidAt`
2. **"Never Forget Unless Told"** - Matches Graphlit's philosophy exactly
3. **Hybrid Search** - Vector + full-text + temporal is the multi-axis approach
4. **Subject Hierarchy via Tags** - Categorization system for organizing propositions
5. **Operations Log** - Audit trail for debugging and compliance
6. **Hive Mind** - Multi-robot shared memory is like organizational context
7. **Working Memory / Long-term Memory** - Maps to the LLM context window problem

---

## Suggested Enhancements (Informed by Event Clock)

To bring HTM closer to the Event Clock architecture:

### 1. Add `deleted_at` Column (if not present)

```sql
ALTER TABLE nodes ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
CREATE INDEX idx_nodes_deleted_at ON nodes(deleted_at);
```

This completes the temporal validity model:
- `created_at` → when the proposition became true
- `deleted_at` → when it stopped being true (null = still valid)

### 2. Add Fact Status

```sql
ALTER TABLE nodes ADD COLUMN status TEXT DEFAULT 'canonical'
  CHECK (status IN ('canonical', 'superseded', 'corroborated', 'synthesized'));
ALTER TABLE nodes ADD COLUMN superseded_by BIGINT REFERENCES nodes(id);
ALTER TABLE nodes ADD COLUMN derived_from BIGINT[] DEFAULT '{}';
```

This enables:
- Marking old propositions as superseded when new information arrives
- Tracking which propositions were synthesized from which source propositions
- Querying only canonical/current propositions

### 3. Add Entity Table

```sql
CREATE TABLE entities (
  id BIGSERIAL PRIMARY KEY,
  canonical_name TEXT NOT NULL,
  entity_type TEXT, -- person, organization, product, place
  aliases TEXT[] DEFAULT '{}',
  merged_from BIGINT[] DEFAULT '{}',
  embedding vector(1536),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE entity_mentions (
  node_id BIGINT REFERENCES nodes(id) ON DELETE CASCADE,
  entity_id BIGINT REFERENCES entities(id) ON DELETE CASCADE,
  mention_text TEXT,
  confidence REAL DEFAULT 1.0,
  PRIMARY KEY (node_id, entity_id)
);

CREATE INDEX idx_entities_type ON entities(entity_type);
CREATE INDEX idx_entities_canonical_name ON entities(canonical_name);
CREATE INDEX idx_entity_mentions_entity_id ON entity_mentions(entity_id);
```

This enables:
- Identity resolution: "Sarah Chen", "S. Chen", "@sarah" → single entity
- Entity-centric queries: "All propositions about this person"
- Relationship reasoning: "Who does this person work with?"

### 4. Add Geospatial (Optional)

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
ALTER TABLE nodes ADD COLUMN location GEOGRAPHY(POINT);
CREATE INDEX idx_nodes_location ON nodes USING gist(location);
```

This enables:
- "What did we discuss in meetings held in New York?"
- Location-aware context retrieval

### 5. Separate Content from Propositions (Optional)

Consider a `content` table for raw source documents:

```sql
CREATE TABLE content (
  id BIGSERIAL PRIMARY KEY,
  source_type TEXT, -- email, transcript, document, slack
  source_uri TEXT,
  raw_text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  robot_id TEXT NOT NULL,
  embedding vector(1536)
);

-- Link propositions to their source content
ALTER TABLE nodes ADD COLUMN source_content_id BIGINT REFERENCES content(id);
```

This creates the three-layer model:
- `content` → immutable evidence
- `entities` → resolved identities
- `nodes` (propositions) → temporal assertions

---

## Summary Score Card

| Dimension | HTM | Event Clock | Match |
|-----------|-----|-------------|-------|
| Temporal Validity | `created_at`/`deleted_at` | `validAt`/`invalidAt` | **95%** |
| Entity Resolution | None | First-class | 0% |
| Fact Status/Resolution | None | Full lifecycle | 0% |
| Multi-axis Search | 4/5 axes | 5/5 axes | 80% |
| Graph Relationships | Tags (subject hierarchy) | Knowledge graph | 20% |
| Audit Trail | Yes | Yes | 90% |
| RAG for LLMs | Yes | Yes | 90% |
| Philosophy ("never forget") | Yes | Yes | 100% |

**Overall:** HTM implements approximately **70%** of the Event Clock vision. The temporal validity model is essentially equivalent (with proper semantic interpretation of `created_at` and addition of `deleted_at`). The remaining gaps are **fact status/resolution** and **entity resolution**.

---

## Implementation Priority (Revised)

Given that temporal validity is already addressed:

1. **High Priority: Fact Status**
   - Enables proposition resolution and supersession
   - Required for synthesized propositions
   - Supports audit/compliance use cases

2. **High Priority: Entity Resolution**
   - Critical for hive mind functionality
   - Enables cross-robot knowledge connection
   - Consider LLM-powered entity extraction

3. **Lower Priority: Geospatial**
   - Nice-to-have for location-aware applications
   - PostGIS is well-supported
   - Can be added incrementally

4. **Lower Priority: Content/Propositions Separation**
   - Architectural change
   - Most valuable if ingesting raw documents
   - Can retrofit existing nodes as needed

---

## Terminology Mapping

For clarity when reading Event Clock literature alongside HTM code:

| Event Clock | HTM | Notes |
|-------------|-----|-------|
| Fact | Proposition / Node | Temporal assertion about the world |
| validAt | created_at | When the proposition became true |
| invalidAt | deleted_at | When it stopped being true |
| Content | (source documents) | Raw evidence, immutable |
| Entity | (not yet implemented) | Resolved identity |
| Context Graph | (not yet implemented) | HTM has `tags` for subject hierarchy, not graph relationships |
| Subject Categories | Tags | Hierarchical classification of propositions |

---

## References

- [Building the Event Clock](building_the_event_clock.md) - Kirk Marple, December 2025
- [Context Graphs: AI's Trillion-Dollar Opportunity](https://foundationcapital.com/context-graphs-ais-trillion-dollar-opportunity/) - Foundation Capital
- [HTM Project](https://madbomber.github.io/htm/) - Hierarchical Temporal Memory documentation
