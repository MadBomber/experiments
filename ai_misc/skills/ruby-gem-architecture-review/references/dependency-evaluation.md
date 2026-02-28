# Dependency Evaluation Framework

Structured approach to evaluating a gem's dependencies.

## The Dependency Cost Model

Every runtime dependency carries costs:

| Cost | Description |
|------|-------------|
| **Version conflicts** | Consumer's other gems may need a different version |
| **Transitive dependencies** | Each dep brings its own deps (dependency tree bloat) |
| **Security surface** | Each dep is a potential vulnerability entry point |
| **Maintenance burden** | Abandoned deps require forking or replacing |
| **Load time** | Each dep adds to boot time |
| **Licensing** | Each dep has license terms that may conflict |

## Evaluation Checklist Per Dependency

For each runtime dependency in the gemspec, answer:

### 1. Is it necessary?

Could the functionality be achieved with:
- Ruby stdlib? (`net/http`, `json`, `openssl`, `csv`, `uri`, `set`, `forwardable`)
- A small inline implementation? (<50 lines of focused code)
- Making it optional? (`defined?(Foo)` guard instead of hard require)

### 2. Is it healthy?

| Signal | Green | Yellow | Red |
|--------|-------|--------|-----|
| Last commit | <6 months | 6-18 months | >18 months |
| Open issues | <50 | 50-200 | >200 or 0 (abandoned) |
| Maintainers | 2+ active | 1 active | 0 active |
| Downloads | >1M total | 100K-1M | <100K |
| CVEs | 0 recent | Patched quickly | Unpatched |

### 3. Is the version constraint appropriate?

```ruby
# Gem libraries: use pessimistic (allows patches + minors)
spec.add_dependency "foo", "~> 2.0"       # >= 2.0, < 3.0

# Broad compatibility (multiple majors)
spec.add_dependency "foo", ">= 1.0", "< 4.0"

# Avoid exact pins (causes conflicts)
spec.add_dependency "foo", "= 2.3.1"      # BAD for gems
```

### 4. What's the transitive impact?

```bash
# Check what a dependency pulls in
gem dependency foo --reverse-dependencies
# Or in Bundler:
bundle viz  # visualize the full dependency graph
```

## Stdlib Replacement Reference

Common dependencies that can be replaced with stdlib:

| Dependency | Stdlib Alternative |
|---|---|
| `httparty`, `rest-client` | `net/http` + `uri` (or `net/http` with a 30-line wrapper) |
| `multi_json` | `json` (bundled with Ruby since 1.9) |
| `hashie` | Plain `Hash` + `Struct` or `Data` (Ruby 3.2+) |
| `activesupport` (for `.blank?`, `.present?`) | Inline: `str.nil? \|\| str.empty?` |
| `activesupport` (for `.camelize`, `.underscore`) | Inline regex or small method |
| `chronic` / `fugit` | `Time.parse` for simple cases |
| `uuid` | `SecureRandom.uuid` |
| `colorize` | ANSI escape codes (5 lines) |
| `dotenv` | `ENV.fetch` with defaults |
| `retryable` | Simple `retry` loop (10 lines) |

## Optional Dependency Pattern

Make dependencies optional when the gem can function without them:

```ruby
# In lib/gemname.rb — don't require at top level
module GemName
  def self.client
    @client ||= if defined?(Elasticsearch::Client)
      Elasticsearch::Client.new
    elsif defined?(OpenSearch::Client)
      OpenSearch::Client.new
    else
      raise Error, "Install elasticsearch or opensearch-ruby gem"
    end
  end
end

# In gemspec — use add_development_dependency only
# Let consumers add the runtime dep themselves
```

```ruby
# Graceful feature detection
module GemName
  def self.redis_available?
    defined?(Redis) && redis_url.present?
  end

  def self.cache(key, &block)
    if redis_available?
      redis_cache(key, &block)
    else
      memory_cache(key, &block)
    end
  end
end
```

## Red Flags in Dependency Usage

| Red Flag | Why It Matters |
|----------|---------------|
| `require "active_support/all"` | Loads the entire ActiveSupport library for one method |
| Depending on a gem for one function | Entire dep tree for `String#camelize` |
| Pinning to exact version | Forces consumers into dependency hell |
| Depending on a fork | Fork may be abandoned, not on RubyGems |
| Depending on git source | Not reproducible, not on RubyGems |
| Runtime dep on test framework | RSpec/Minitest as runtime dep instead of dev dep |

## Reporting Format

For each dependency in a review, produce:

```markdown
### `dependency_name` (~> x.y)

- **Purpose**: What the gem uses it for
- **Necessity**: Required / Could be optional / Could be replaced with stdlib
- **Health**: Green / Yellow / Red
- **Transitive deps**: N additional gems pulled in
- **Recommendation**: Keep / Make optional / Replace with [alternative]
```
