# Benefits of Event Clock Concepts for HTM

**Date:** January 8, 2026 (Updated)
**Context:** Analysis of whether HTM would benefit from implementing concepts from Kirk Marple's "Building the Event Clock" article.

---

## Executive Summary

HTM already implements the core temporal validity model from Event Clock. The terminology differs, but the concepts align:

| Event Clock | HTM | Status |
|-------------|-----|--------|
| Fact | Proposition/Node | **Already equivalent** |
| `validAt` | `created_at` | **Already equivalent** (semantic: when proposition became true) |
| `invalidAt` | `deleted_at` | **Already equivalent** (when proposition stopped being true) |
| Fact Status | — | **Gap: implement this** |
| Entity Resolution | — | **Gap: implement this** |

The highest-value addition is now **fact status** (canonical, superseded, synthesized), followed by **entity resolution** for the hive mind feature.

---

## What HTM Already Has

### Temporal Validity (Already Implemented)

HTM's `created_at` and `deleted_at` are semantically equivalent to Event Clock's `validAt` and `invalidAt`:

- **`created_at`** = when the proposition became true (not when the database row was inserted)
- **`deleted_at`** = when the proposition stopped being true (null = still valid)

**This is a naming/semantic choice, not a structural limitation.** The temporal validity model is already present.

**Query Examples (already possible):**
```sql
-- What's currently true?
SELECT * FROM nodes WHERE deleted_at IS NULL;

-- What was true in Q3 2024?
SELECT * FROM nodes
WHERE created_at <= '2024-09-30'
AND (deleted_at > '2024-07-01' OR deleted_at IS NULL);
```

**Ruby API (if not already present):**

```ruby
# Invalidate a proposition (mark when it stopped being true)
def invalidate(key, as_of: Time.now)
  # UPDATE nodes SET deleted_at = as_of WHERE key = key
end

# Recall only currently-valid propositions
def recall_current(topic:, ...)
  # WHERE deleted_at IS NULL
end

# Recall propositions as they were at a specific point in time
def recall_as_of(topic:, date:, ...)
  # WHERE created_at <= date AND (deleted_at > date OR deleted_at IS NULL)
end
```

### Temporal Query Patterns

Temporal queries fall into three patterns: **past**, **present**, and **future**.

| Pattern | Example Query | HTM Support |
|---------|---------------|-------------|
| **Present** | "Does Danny work at Microsoft?" | **Yes** — `WHERE deleted_at IS NULL` |
| **Past** | "Did Danny work at Microsoft in 1998?" | **Yes** — filter by `created_at` range |
| **Future** | "Will Danny work at Microsoft next year?" | **Limited** — see below |

**The Asymmetry:**
- **Past and Present** are *memory* — recorded assertions about what was/is true
- **Future** is *prediction* — speculation about what might become true

HTM is a **memory system**. It answers "what do we know?" not "what do we expect?"

**Special Case — Planned Future Facts:**

Scheduled/planned events can be stored with a future `created_at`:

```ruby
# Danny accepted an offer, starts January 15, 2027
htm.add_node("danny_microsoft_future",
             "Danny will work at Microsoft as Senior Engineer",
             created_at: Time.parse("2027-01-15"),  # Future validity
             type: :fact)
```

This isn't prediction — it's a recorded assertion about a **planned future state**.

**Temporal States:**

| State | `created_at` | `deleted_at` | Meaning |
|-------|-------------|--------------|---------|
| **Historical** | Past | Past | Was true, no longer true |
| **Current** | Past | NULL | Is true now |
| **Planned** | Future | NULL | Scheduled to become true |
| **Cancelled** | Future | Not NULL | Was planned, now cancelled |

True future prediction requires inference, probabilistic reasoning, or external models — outside the scope of a memory system.

---

## High-Value Additions (Remaining Gaps)

### 1. Fact Status (Canonical, Superseded, Synthesized)

**Benefit:** Know which propositions to trust when multiple exist.

**The Problem Today:**

```ruby
htm.add_node("user_location_001", "User lives in Austin", type: :fact)
# ... 6 months later ...
htm.add_node("user_location_002", "User lives in Denver", type: :fact)

# RAG retrieval might return BOTH propositions
# LLM now sees contradictory information
```

**With Fact Status:**

```ruby
htm.add_node("user_location_002", "User lives in Denver",
             type: :fact,
             supersedes: "user_location_001")
# Old proposition marked as :superseded
# RAG only returns canonical propositions by default
```

**For HTM specifically:**
- The "hive mind" feature means multiple robots may record propositions about the same things
- Without status, you can't resolve conflicts
- Synthesized propositions enable "Paula worked at Google 2020-2024" from scattered mentions

**Implementation Cost:** Medium. Schema changes + resolution logic.

**Verdict:** **Implement this.** Critical for long-running systems and hive mind.

---

### 2. Entity Resolution

**Benefit:** Connect scattered mentions to unified identities.

**The Problem:**

```ruby
# Robot 1 records:
htm.add_node("meeting_001", "Met with Sarah Chen about the API")

# Robot 2 records:
htm.add_node("email_042", "S. Chen approved the budget")

# Robot 3 records:
htm.add_node("slack_msg", "@sarah_c mentioned timeline concerns")

# Query: "What do we know about Sarah Chen?"
# Result: Only finds meeting_001, misses the other two
```

**For HTM's Hive Mind:**

This is where HTM's multi-robot architecture *really* needs entity resolution. Different robots will refer to the same people, projects, and concepts differently. Without entity linking, the "hive mind" is actually fragmented minds that can't connect their knowledge.

**Implementation Cost:** High. Requires:
- Entity extraction (NER or LLM-based)
- Alias clustering
- Merge/resolution logic
- Possibly LLM calls for ambiguous cases

**Verdict:** **Implement this** for full hive mind functionality. Start with:
- Manual entity creation for important actors
- Simple alias matching
- LLM-assisted resolution for new mentions

---

## Medium-Value Additions

### 3. Content vs Propositions Separation

**Benefit:** Preserve raw evidence separate from extracted assertions.

**When it matters:**
- Ingesting documents, emails, transcripts
- Need to trace propositions back to source
- Compliance/audit requirements

**For HTM:**
- Current `nodes` table mixes content and propositions
- Less critical if you're only storing discrete propositions
- More critical if you're ingesting raw documents

**Verdict:** **Optional.** Implement if you plan to ingest unstructured documents.

---

### 4. Geospatial

**Benefit:** Location-aware retrieval.

**For HTM:**
- Only valuable if your use case is location-sensitive
- "What did we discuss in the NYC office?" type queries
- Most coding/assistant use cases don't need this

**Verdict:** **Skip unless needed.** Easy to add later with PostGIS.

---

## Practical Recommendation

Given that HTM already has temporal validity, prioritize:

### Phase 1: Fact Status (High Priority)

**Schema Changes:**

```sql
ALTER TABLE nodes ADD COLUMN status TEXT DEFAULT 'canonical'
  CHECK (status IN ('canonical', 'superseded', 'corroborated', 'synthesized'));
ALTER TABLE nodes ADD COLUMN superseded_by BIGINT REFERENCES nodes(id);
ALTER TABLE nodes ADD COLUMN derived_from BIGINT[] DEFAULT '{}';

CREATE INDEX idx_nodes_status ON nodes(status);
```

**Ruby API Additions:**

```ruby
# Add node that supersedes another
def add_node(key, value, supersedes: nil, ...)
  node_id = # ... create node ...

  if supersedes
    mark_superseded(supersedes, by: node_id)
  end

  node_id
end

# Mark a proposition as superseded
def mark_superseded(key, by:)
  # UPDATE nodes SET status = 'superseded', superseded_by = by WHERE key = key
end

# Create a synthesized proposition from multiple source propositions
def synthesize(key, value, from:, ...)
  add_node(key, value,
           status: :synthesized,
           derived_from: from,
           ...)
end

# Recall only canonical propositions (default behavior)
def recall(topic:, include_superseded: false, ...)
  # WHERE status = 'canonical' (unless include_superseded)
end
```

---

### Phase 2: Entity Resolution (High Priority for Hive Mind)

**Schema Changes:**

```sql
CREATE TABLE entities (
  id BIGSERIAL PRIMARY KEY,
  canonical_name TEXT NOT NULL,
  entity_type TEXT CHECK (entity_type IN ('person', 'organization', 'project', 'product', 'place')),
  aliases TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  embedding vector(1536),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE entity_mentions (
  id BIGSERIAL PRIMARY KEY,
  node_id BIGINT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  entity_id BIGINT NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
  mention_text TEXT NOT NULL,
  confidence REAL DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(node_id, entity_id, mention_text)
);

CREATE INDEX idx_entities_type ON entities(entity_type);
CREATE INDEX idx_entities_canonical_name ON entities(canonical_name);
CREATE INDEX idx_entities_aliases ON entities USING gin(aliases);
CREATE INDEX idx_entity_mentions_entity_id ON entity_mentions(entity_id);
CREATE INDEX idx_entity_mentions_node_id ON entity_mentions(node_id);
```

**Ruby API Additions:**

```ruby
# Create or find an entity
def ensure_entity(name, type:, aliases: [])
  # Check existing entities by name or alias
  # Create if not found
end

# Link a proposition to an entity
def link_entity(node_key, entity_id, mention_text:, confidence: 1.0)
  # INSERT INTO entity_mentions ...
end

# Find all propositions about an entity
def propositions_about(entity_id)
  # JOIN nodes with entity_mentions
end

# Merge two entities (identity resolution)
def merge_entities(keep_id, merge_id)
  # Update all mentions to point to keep_id
  # Add merged entity's aliases to keep_id
  # Delete merged entity
end
```

**Start Simple:**
- Manually create entities for key actors
- Auto-link exact name matches
- LLM-assisted resolution for new mentions (optional enhancement)

---

## When NOT to Implement

Skip the remaining Event Clock enhancements if HTM is primarily used for:

- **Short-lived sessions** — Propositions don't change within a single conversation
- **Single-robot scenarios** — No cross-context ambiguity to resolve
- **Code-only memory** — Explicit identifiers, no entity ambiguity
- **Append-only use cases** — Historical record where supersession doesn't matter

---

## Decision Matrix (Revised)

| Concept | Implement? | Value | Cost | Priority |
|---------|-----------|-------|------|----------|
| Temporal Validity | **Already present** | — | — | — |
| Fact Status | **Yes** | High | Medium | 1 |
| Entity Resolution | **Yes** (for hive mind) | High | High | 2 |
| Content/Propositions Split | **Later** | Medium | Medium | 3 |
| Geospatial | **No** | Low | Low | — |

---

## Expected Outcomes

### With Fact Status:

1. **No more contradictory propositions** — LLM context is consistent
2. **Historical queries work** — "What did we know in Q3?"
3. **Proposition lineage** — Know which propositions superseded which
4. **Cleaner RAG** — Only retrieve currently-valid, canonical propositions

### With Entity Resolution (additional):

1. **True hive mind** — Cross-robot knowledge actually connects
2. **Entity-centric queries** — "Everything about Project X"
3. **Relationship reasoning** — "Who works with Sarah?"
4. **Reduced duplication** — Same entity stored once, referenced many times

---

## Bottom Line

HTM already has the temporal validity foundation that Event Clock describes. The `created_at`/`deleted_at` model is semantically equivalent to `validAt`/`invalidAt`—it's just named differently.

The remaining high-value additions are:

1. **Fact Status** — Transform HTM from "memory that records" to "memory that knows what's currently true"
2. **Entity Resolution** — Transform the hive mind from "fragmented memories" to "connected organizational intelligence"

These changes align perfectly with HTM's "never forget" philosophy. You're not deleting old propositions; you're marking them as superseded or linking them to resolved entities. The audit trail remains complete, but your LLM gets clean, consistent, current context.

---

## Terminology Mapping

For clarity when reading Event Clock literature alongside HTM code:

| Event Clock | HTM | Notes |
|-------------|-----|-------|
| Fact | Proposition / Node | Temporal assertion about the world |
| validAt | created_at | When the proposition became true |
| invalidAt | deleted_at | When it stopped being true |
| Content | (source documents) | Raw evidence, immutable |
| Entity | (to be implemented) | Resolved identity |
| Context Graph | (not yet implemented) | HTM has `tags` for subject hierarchy, not graph relationships |
| Subject Categories | Tags | Hierarchical classification of propositions |

---

## References

- [Building the Event Clock](building_the_event_clock.md) — Kirk Marple, December 2025
- [HTM Gap Analysis](htm_gaps.md) — Comparison of HTM vs Event Clock concepts
- [HTM Project](https://madbomber.github.io/htm/) — Hierarchical Temporal Memory documentation
