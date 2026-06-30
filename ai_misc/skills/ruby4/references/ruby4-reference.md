# Ruby 4.0 Reference: Features, Idioms, and Breaking Changes

## Modern Idioms (Baseline since Ruby 3.1–3.4)

These features predate 4.0 but are now the unconditional standard. Never write the "old" form.

### Hash Value Omission (Ruby 3.1+)
```ruby
# Old — never write this
{ user: user, project: project, account: account }
create_session(user: user)

# Modern
{ user:, project:, account: }
create_session(user:)
```

### Anonymous Block Parameter `it` (Ruby 3.4+)
```ruby
# Old
numbers.map { |n| n * 2 }
users.select { |u| u.active? }

# Modern
numbers.map { it * 2 }
users.select { it.active? }
```

### Numbered Block Parameters (Ruby 2.7+)
```ruby
# Old
pairs.map { |a, b| a + b }

# Modern (when names add no clarity)
pairs.map { _1 + _2 }
```

### Endless Method Definition (Ruby 3.0+)
```ruby
# Old
def double(x)
  x * 2
end

# Modern (single-expression methods)
def double(x) = x * 2
```

### `Data.define` for Immutable Value Objects (Ruby 3.2+)
```ruby
# Old
Struct.new(:x, :y, keyword_init: true)

# Modern — immutable, no setters
Point = Data.define(:x, :y)
p = Point.new(x: 1, y: 2)
```

### Rightward Assignment (Ruby 3.0+)
```ruby
# Optional style for pipelines
transform(value) => result
```

### Pattern Matching (Ruby 3.0+)
```ruby
case response
in { status: 200, body: String => body }
  process(body)
in { status: 404 }
  not_found
end

# Find pattern
case data
in [*, { name: /Alice/ => entry }, *]
  entry
end

# One-line deconstruct
user => { name:, email: }
```

---

## Ruby 4.0 New Language Behavior

### Logical Operator Line Continuation
Logical operators at line-start now continue the previous line — no backslash needed.
```ruby
if condition1
   && condition2
   && condition3
  do_something
end
```

### `*nil` Splat Change
`*nil` no longer calls `nil.to_a` — it produces an empty list, matching `**nil`.
```ruby
# Both now behave the same way (empty expansion)
foo(*nil)
foo(**nil)
```

---

## Ruby 4.0 New Core Methods

### Array
```ruby
# Array#rfind — reverse find (faster than .reverse_each.find)
[1, 2, 3, 2, 1].rfind { it > 1 }  # => 2 (last match)
```

### Enumerator
```ruby
# Enumerator.produce with size hint
Enumerator.produce(1, size: Float::INFINITY, &:succ)
```

### IO
```ruby
# IO.select now accepts Float::INFINITY
IO.select(readers, nil, nil, Float::INFINITY)
```

### Math
```ruby
Math.log1p(x)   # ln(1 + x), accurate for small x
Math.expm1(x)   # e^x - 1, accurate for small x
```

### String strip selectors
```ruby
# Strip only specific characters
"--hello--".strip(" -")   # => "hello"
```

### Fiber / Thread raise with cause
```ruby
fiber.raise(RuntimeError, "msg", cause: original_error)
thread.raise(RuntimeError, "msg", cause: original_error)
```

---

## Promoted to Core (No `require` Needed)

| Class/Lib | Notes |
|-----------|-------|
| `Set` | `require 'set'` no longer needed. Inspect output simplified: `Set[1, 2, 3]` |
| `Pathname` | `require 'pathname'` no longer needed |

---

## Ruby Module (New Top-Level Constant)
```ruby
Ruby::VERSION       # => "4.0.5"
Ruby::PLATFORM      # platform string
Ruby::RELEASE_DATE  # release date string
```

---

## Ruby::Box (Experimental — `RUBY_BOX=1`)
Isolates monkey patches, globals, class definitions, and loaded libraries between boxes.
Use cases: protecting test suites from side effects, blue-green parallel app instances.
Not production-ready; may change in 4.1.

---

## Ractor Redesign (Breaking)

### New API
```ruby
port = Ractor::Port.new

r = Ractor.new(port) do |port|
  port << compute_result
end

result = port.receive
r.join   # wait for termination
```

### Shareable Callables
```ruby
fn = Ractor.shareable_proc { |x| x * 2 }
lm = Ractor.shareable_lambda { |x| x + 1 }
```

### Removed — Do Not Use
- `Ractor.yield` → use `Ractor::Port`
- `Ractor#take` → use `port.receive`
- `Ractor#close_incoming` / `#close_outgoing` → removed

---

## JIT

- `--rjit` removed. Do not reference RJIT.
- `--yjit` — production-ready JIT (same as 3.x)
- `--zjit` — new experimental Rust-based JIT, not yet production-ready

---

## Breaking Changes / Removals

### Removed Methods — Never Generate These
| Symbol | Replacement |
|--------|-------------|
| `ObjectSpace._id2ref` | removed, no drop-in |
| `Process::Status#&` | use `#exitstatus`, `#signaled?` etc. |
| `Process::Status#>>` | use named predicates |
| `Ractor.yield` | `Ractor::Port` |
| `Ractor#take` | `port.receive` |
| `SortedSet` | add gem `sorted_set` |

### Pipe-Based Process Creation — Removed
```ruby
# Never generate this — removed in 4.0
open("|ls")
Kernel.open("|cmd")
```

### CGI Library — Mostly Removed
Only escape helpers remain. Do not `require 'cgi'` for form/cookie/session handling.
Use Rack or framework abstractions instead.
```ruby
# Still available
CGI.escape(str)
CGI.unescape(str)
CGI.escapeHTML(str)
CGI.unescapeHTML(str)
CGI.escapeURIComponent(str)
```

### Net::HTTP — Content-Type No Longer Auto-Set
```ruby
# Old behavior (relied on auto Content-Type) — broken in 4.0
http.post("/path", "a=1&b=2")

# Correct 4.0 form
http.post("/path", "a=1&b=2", "Content-Type" => "application/x-www-form-urlencoded")
```

### Set#to_set Arguments Deprecated
```ruby
# Deprecated
[1, 2, 3].to_set(MySet)

# Use
MySet.new([1, 2, 3])
```

---

## Stdlib Still Requiring `require` (Not Promoted to Core)
These remain gems / stdlib — still need explicit require:
`json`, `csv`, `date`, `uri`, `net/http`, `open3`, `fileutils`, `tempfile`, `digest`, etc.

---

## Backtrace Changes (4.0)
- `internal:` frames no longer appear in backtraces
- `ArgumentError` messages include receiver class: `Foo#bar` instead of just `bar`
- Both caller and callee shown for argument mismatches

---

## Platform Notes
- Windows requires MSVC 14.0+ (Visual Studio 2015+)
- `File::Stat#birthtime` now works on Linux (via statx)
