---
name: rails-query
description: |
  Answer any question that requires live data from a Rails 8.2+ app using `rails query`:
  counts, lookups, "how many X", ad-hoc investigation, schema exploration, EXPLAIN plans,
  and aggregates — whether locally or against a deployed environment via Kamal. Trigger
  broadly whenever the user asks for data from a Rails app's database, mentions
  `rails query` / `bin/rails query` / `bin/kamal query`, asks to inspect schema, tables,
  or models, wants to run SQL or ActiveRecord against the database, needs an EXPLAIN
  plan, or wants to query production/staging/replica. Prefer this skill over opening a
  Rails console, SSH-ing to a server, or writing a one-off script for data questions —
  `rails query` is faster, structured (JSON output), audit-friendly, and read-only by
  construction.
---

# rails-query

`rails query` is a Rails 8.2+ command for running read-only queries against the database. Input is a single expression, output is a single JSON object on stdout (`{columns, rows, meta}`; errors go to stderr with non-zero exit), and writes are blocked at the connection level. With a read replica configured it hits the replica automatically, so it's safe to point at production.

Prefer it over a console, a script, or SSH for any data question. One invocation, structured output, nothing to clean up.

## The flow

### 1. Know where you're running

- **Local** (`bin/rails query`) — development, tests, or anywhere you have the app checked out.
- **Remote via Kamal** (`bin/kamal query -d <destination>`) — when the app is deployed with Kamal. Requires a small alias in `config/deploy.yml` (see "Kamal setup").

If you don't know whether Kamal is configured, check `config/deploy.yml` for an `aliases:` block.

### 2. Decide: Ruby expression or raw SQL

**Default: Ruby (ActiveRecord).** The expression is `eval`'d in the app context — scopes, associations, finders, aggregates all work. Model logic (encryption, default scopes, polymorphism) is honored.

**`--sql`:** raw schema access, cross-table joins without models, or aggregates awkward in AR.

Telltale sign you forgot `--sql`: `SyntaxError: unexpected *; no anonymous rest parameter` — your SQL got parsed as Ruby. Add `--sql` and retry.

### 3. Inspect the schema if it's unfamiliar

`rails query` has three introspection modes that work the same locally and remotely — crucial when you only have Kamal access:

```bash
bin/rails query schema           # every table
bin/rails query schema users     # columns + indexes + enums + associations for one table
bin/rails query models           # every AR model with its table and associations
```

Enums matter: if a column is an enum, `User.where(status: "active")` works but `User.where(status: 0)` might silently misfire. `schema <table>` tells you.

**Over Kamal, cache the schema locally before `jq`-ing it** — each round-trip is 10-30s. Dump `schema` / `models` / `schema <table>` to `/tmp/rails-query-cache-<env>/` once, then `jq` against the files. Skip caching for single-query tasks or local runs.

### 4. For expensive queries, `EXPLAIN` first

```bash
bin/rails query explain 'User.where(active: true).order(:created_at).limit(100)'
bin/rails query explain 'SELECT * FROM users WHERE active = 1' --sql
```

Do this before running full-table scans against production.

### 5. Run the query

```bash
bin/rails query 'User.count'
bin/rails query --sql 'SELECT COUNT(*) FROM users'
```

Watch for `"has_more": true` in the response — pagination is truncating. Re-run with `--page N` or raise `--per`. Don't add your own `LIMIT`; see "Pagination".

### 6. Extract what you need

```bash
bin/rails query 'User.count' | jq '.rows[0][0]'                  # single scalar
bin/rails query 'User.pluck(:email)' | jq -r '.rows[][0]'        # column as array
COUNT=$(bin/rails query 'User.count' | jq -r '.rows[0][0]')      # into a shell var
```

## Command reference

```bash
bin/rails query [OPTIONS] '<expression>'
bin/kamal query -d <destination> [OPTIONS] '<expression>' 2>/dev/null
```

| Flag | Default | Meaning |
|------|---------|---------|
| `--sql` | off | Treat `<expression>` as raw SQL instead of Ruby/AR |
| `--db <name>` | — | Explicit database config (e.g. `primary_replica`, `analytics`) |
| `-e <env>` | `development` | Environment (`test`, `production`, …) |
| `--page N` | 1 | Page number (1-indexed) |
| `--per N` | 100 | Rows per page (max 10000) |

### Special expressions (no `--sql` needed)

| Expression | What it returns |
|------------|-----------------|
| `schema` | Every table name |
| `schema <table>` | Columns, indexes, enums, and associations for that table |
| `models` | Every AR model with its table and associations |
| `explain <expr>` | `EXPLAIN` plan. Pair with `--sql` for raw SQL |
| `-` (or piped stdin) | Read expression from stdin — useful for long multi-line SQL |

## Pagination

`rails query` paginates automatically. It internally appends `LIMIT per+1` to detect whether more rows exist, which drives `meta.has_more`.

**Don't add your own `LIMIT`.** If the SQL already contains `LIMIT`, the command won't add one — which suppresses the truncation detector. For raw SQL, omit `LIMIT` and let pagination handle it.

```bash
bin/rails query --sql 'SELECT id, email FROM users ORDER BY id' --page 2
bin/rails query --per 500 'User.order(:id)'
```

Always order explicitly when paginating — without `ORDER BY`, page 2 can overlap page 1.

## Kamal setup

If the app deploys with Kamal, add this to `config/deploy.yml`:

```yaml
aliases:
  # -q: quiet (only JSON on stdout); --reuse: use running container; -p: pin to primary host
  # (avoids duplicate output); -r console: run on the console role (should have replica access)
  query: 'app exec -q --reuse -p -r console "rails query"'
```

Then:

```bash
bin/kamal query -d production 'User.count' 2>/dev/null
bin/kamal query -d production --sql 'SELECT COUNT(*) FROM users' 2>/dev/null
```

`2>/dev/null` suppresses SSH noise; the JSON result goes to stdout.

### The Kamal quoting rule

When your expression contains shell metacharacters — especially `(`, `)`, `*`, `;`, `&`, `|`, `<`, `>` — the remote shell eats a single layer of quoting. The argument passes through your local shell, Ruby arg parsing in Kamal, SSH, and finally `bash -c` on the remote host; one of those strips quotes.

**The reliable pattern:** outer single quotes, inner double quotes.

```bash
# WORKS — inner double quotes survive to the remote shell and protect the parens
bin/kamal query -d production --sql '"SELECT COUNT(*) FROM users"'
bin/kamal query -d production '"User.where(active: true).count"'

# FAILS — bash: -c: syntax error near unexpected token '('
bin/kamal query -d production --sql 'SELECT COUNT(*) FROM users'
```

For SQL containing single-quoted string literals, prefer the Ruby form — usually cleaner than escaping:

```bash
bin/kamal query -d production '"User.where(email: \"alice@example.com\").pick(:id)"'
```

**Locally, single-layer quoting works normally** — the nested-quote dance is purely a Kamal remoting artifact.

## Common patterns

```bash
# Counts and aggregates
bin/rails query 'User.where(active: true).count'
bin/rails query 'User.group(:role).count'

# Lookups
bin/rails query 'User.find_by(email: "alice@example.com")&.as_json'

# Joins and scopes — Ruby form reuses existing scopes/encryption
bin/rails query 'Post.published.joins(:author).where(authors: { verified: true }).count'

# Schema-first discovery
bin/rails query schema orders | jq '.columns[] | {name, type, null}'
bin/rails query models | jq '.[] | select(.table_name == "accounts") | .model'
```

## Safety model

- Writes are blocked at the connection level via `while_preventing_writes` or (when configured) `connected_to(role: :reading)`. `INSERT` / `UPDATE` / `DELETE` raises instead of executing.
- With a read replica configured, queries hit the replica automatically.
- `--db <name>` overrides the connection (e.g. `--db primary_replica`, `--db analytics`).

`ActiveRecord::ReadOnlyError` means the safety net fired — rework the expression to be read-only.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `SyntaxError: unexpected *` | SQL passed without `--sql` | Add `--sql` |
| `bash: -c: syntax error near unexpected token '('` | Kamal path, single-layer quoting | Switch to `'"..."'` nested quotes |
| `ActiveRecord::ReadOnlyError` | Expression tried to write | Rework to be read-only |
| Empty JSON or duplicated output over Kamal | Missing `-p` or `-q` in the alias | Add them to `config/deploy.yml` |
| `LIMIT 101` in `meta.sql` unexpectedly | Default pagination probe | Expected — drives `meta.has_more` |
| `has_more: true` but you wanted all rows | Default per-page hit | Raise `--per` (max 10000) or paginate with `--page` |
| `ActiveRecord::ConnectionNotEstablished` with `--db` | Database key not in `database.yml` | Check the env's `database.yml` for the exact key |

## Further reading

- Rails source: `railties/lib/rails/commands/query/query_command.rb` in the Rails repo
- Kamal `app` commands: https://kamal-deploy.org/docs/commands/app/
