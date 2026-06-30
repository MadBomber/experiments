---
name: ruby4
description: Enforces idiomatic Ruby 4.0 code generation. This skill should be used whenever writing, reviewing, or refactoring Ruby code in a Ruby 4.0+ project. It ensures modern idioms (hash shorthand, `it` block param, endless methods, Data.define, pattern matching) are used by default and prevents generation of removed APIs (RJIT, pipe-based open, ObjectSpace._id2ref, old Ractor API, SortedSet, full CGI) and pre-4.0 patterns that have cleaner modern equivalents.
---

# Ruby 4.0 Idiomatic Code

## Overview

Ruby 4.0 (released December 2025) establishes new language baselines. Write code that reflects 4.0 standards — not Ruby 2.x/3.0-era habits. The full change reference is in `references/ruby4-reference.md`. Load it at the start of any Ruby 4.0 task.

## Workflow

1. Read `references/ruby4-reference.md` before generating or reviewing Ruby code.
2. Apply the idiom rules below as non-negotiable defaults.
3. Flag any pattern from the "Never Generate" list if found in existing code under review.

## Non-Negotiable Modern Idioms

Apply unconditionally. Do not fall back to the old form under any circumstance.

### Hash shorthand — always omit redundant value
```ruby
# Wrong
{ user: user, project: project }
create_session(user: user)

# Right
{ user:, project: }
create_session(user:)
```

### Anonymous block param — use `it` for single-param blocks
```ruby
# Wrong
numbers.map { |n| n * 2 }

# Right
numbers.map { it * 2 }
```

### Endless method — use for all single-expression methods
```ruby
# Wrong
def double(x)
  x * 2
end

# Right
def double(x) = x * 2
```

### `Data.define` — use instead of `Struct` for immutable value objects
```ruby
# Wrong
Point = Struct.new(:x, :y, keyword_init: true)

# Right
Point = Data.define(:x, :y)
```

### Set and Pathname — no require needed
```ruby
# Wrong
require 'set'
require 'pathname'

# Right — they are core classes in 4.0
set = Set.new([1, 2, 3])
path = Pathname.new("/tmp")
```

### Net::HTTP — always set Content-Type explicitly
```ruby
# Wrong — Content-Type no longer auto-set in 4.0
http.post("/path", body)

# Right
http.post("/path", body, "Content-Type" => "application/x-www-form-urlencoded")
```

## Never Generate — Removed APIs

| Removed | Use Instead |
|---------|-------------|
| `--rjit` / RJIT references | `--yjit` (stable) or `--zjit` (experimental) |
| `open("\|cmd")` / `Kernel.open("\|cmd")` | `IO.popen`, `Open3.capture2` |
| `ObjectSpace._id2ref` | removed; restructure code |
| `Process::Status#&` / `#>>` | `#exitstatus`, `#signaled?`, `#stopped?` |
| `Ractor.yield` | `Ractor::Port#<<` |
| `Ractor#take` | `port.receive` |
| `Ractor#close_incoming` / `#close_outgoing` | removed |
| `SortedSet` | add gem `sorted_set` |
| `require 'cgi'` for full CGI | Rack / framework; only escape helpers remain |
| `ObjectSpace._id2ref` | removed |

## Ractor — Use Port API
```ruby
# Wrong (old API — removed)
result = ractor.take

# Right (4.0 Port API)
port = Ractor::Port.new
r = Ractor.new(port) { |p| p << compute }
result = port.receive
r.join
```

## Key 4.0 Additions Worth Using

- `Array#rfind { it > x }` — reverse find, faster than `.reverse_each.find`
- `IO.select(readers, nil, nil, Float::INFINITY)` — infinite timeout now accepted
- `Math.log1p(x)` / `Math.expm1(x)` — numerically stable math
- `"--text--".strip("-")` — strip by character selector
- `Fiber#raise(cause:)` / `Thread#raise(cause:)` — chained exception cause
- `Ruby::VERSION` / `Ruby::PLATFORM` — top-level `Ruby` module constants
- Logical operators at line-start continue the previous line (no backslash needed)

## Pattern Matching — Use Freely (Stable Since 3.0)
```ruby
case response
in { status: 200, body: String => body }
  process(body)
in { status: 422, errors: [*, String => first, *] }
  report(first)
end
```

## Reference

Full details, before/after examples, and edge cases: `references/ruby4-reference.md`
