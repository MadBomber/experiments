# Decision Log

Record architectural and design decisions as they happen. Each entry captures the context that will be invisible in 6 months.

## Template

```
### YYYY-MM-DD — Short Title

**Status:** Accepted | Superseded by [link] | Deprecated

**Context:** What situation or constraint prompted this decision?

**Decision:** What was chosen?

**Reasoning:** Why this approach over the alternatives? What trade-offs were weighed?

**Alternatives considered:**
- Alternative A — why it was rejected
- Alternative B — why it was rejected
```

## Example

### 2026-02-15 — Use SQLite instead of PostgreSQL

**Status:** Accepted

**Context:** Single-user CLI tool with modest data volume (<100k rows). No concurrent write pressure. Deployment targets machines without guaranteed Postgres access.

**Decision:** Use SQLite via the sqlite3 gem.

**Reasoning:** Zero-config deployment matters more than concurrent write throughput for this use case. SQLite's single-file storage simplifies backup and portability.

**Alternatives considered:**
- PostgreSQL — adds deployment complexity for no benefit at this scale
- JSON flat files — no query capability, fragile under concurrent access
