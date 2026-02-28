---
name: ruby-gem-architecture-review
description: >
  Perform architectural review of Ruby gems and libraries.
  Evaluate API design, module organization, dependency management,
  Rails integration safety, testability, and extension patterns.
  Use when reviewing an existing gem's architecture, auditing a gem
  before adoption, preparing a gem for open-source release, or
  refactoring a library's internal structure. Complements the
  andrew-kane-gem-writer skill which handles gem creation.
---

# Ruby Gem Architecture Review

Perform structured architectural review of Ruby gems and libraries. Evaluate design
decisions against proven patterns from high-quality gems (Searchkick, Strong Migrations,
Devise, Dry-rb, Sorbet, ActiveSupport).

## When to Use

- Reviewing an existing gem's codebase before contributing or adopting
- Auditing internal libraries before extracting to standalone gems
- Preparing a gem for open-source release
- Refactoring a gem that has grown beyond its original design
- Evaluating whether a gem's architecture will scale

## Review Process

Execute each phase in order. Skip phases only when explicitly irrelevant.

### Phase 1: Structural Inventory

Map the gem's physical structure before evaluating quality.

**Actions:**

1. Read the gemspec for metadata, dependencies, and file patterns
2. Map the directory layout under `lib/`
3. Identify the entry point (`lib/gemname.rb`) and trace the require graph
4. Count public classes/modules vs internal implementation
5. Note any non-Ruby files (C extensions, FFI bindings, YAML configs, templates)

**Produce a structural summary:**

| Metric | Value | Notes |
|--------|-------|-------|
| Entry point | `lib/gemname.rb` | |
| Total Ruby files | N | |
| Public modules/classes | N | Exposed to consumers |
| Internal modules/classes | N | Implementation detail |
| Runtime dependencies | N | List them |
| Lines of code (approx) | N | Excluding tests |
| Test files | N | Framework used |
| C extensions / FFI | Yes/No | |

---

### Phase 2: API Surface Review

Evaluate what consumers interact with.

**Check each item:**

1. **Entry point clarity** — Does `require "gemname"` make the full public API available?
   Does it load too much (eager) or too little (missing requires)?

2. **Public API size** — How many public methods/classes must a consumer understand
   to use the gem? Fewer is better. Flag gems where the consumer must know >10 classes.

3. **Configuration pattern** — How is the gem configured?
   - Preferred: Module-level `attr_accessor` with sensible defaults (Kane pattern)
   - Acceptable: `configure` block yielding a config object
   - Problematic: Global variables, environment-only config, scattered constants

4. **Error hierarchy** — Does the gem define a base `Error < StandardError`?
   Are errors specific enough to rescue selectively?

5. **Method signatures** — Do public methods use keyword arguments for clarity?
   Are required vs optional parameters obvious? Flag positional args beyond 2.

6. **Return types** — Are return types consistent and predictable?
   Flag methods that return mixed types (sometimes Array, sometimes nil).

7. **Thread safety** — Does the gem use mutable class-level state?
   Flag `@@class_variables`, unprotected `@instance_variables` on modules,
   and shared mutable hashes/arrays without synchronization.

8. **Namespace pollution** — Does the gem monkey-patch core classes (String, Array, Object)?
   Does it add methods to classes it doesn't own without using `prepend` or `refinements`?

**Severity guide:**

| Issue | Severity |
|-------|----------|
| Monkey-patching core classes | Critical |
| Thread-unsafe shared mutable state | Critical |
| No base error class | Important |
| Positional args > 2 | Suggestion |
| Mixed return types | Important |
| Configuration via globals/ENV only | Important |

---

### Phase 3: Module Organization Review

Evaluate internal structure and separation of concerns.

**Check each item:**

1. **Single Responsibility** — Does each file/class have one clear purpose?
   Flag files >300 lines or classes with >15 public methods.

2. **Layering** — Is there separation between:
   - Public API (what consumers call)
   - Core logic (algorithms, transformations)
   - Integration layer (Rails hooks, framework adapters)
   - I/O layer (HTTP clients, database queries, file access)

3. **Require graph** — Are requires explicit (`require_relative`) or implicit (autoload)?
   Flag circular requires. Trace the load order for correctness.

4. **Method decomposition** — For large classes (>200 lines), does the gem use
   the include-modules-by-feature pattern? (See `references/decomposition-patterns.md`)

5. **Internal vs Public distinction** — Are internal modules clearly separated
   from the public API? Check for:
   - `@api private` annotations or `# :nodoc:` comments
   - Private constants or nested modules consumers shouldn't touch
   - Underscore-prefixed files or directories (convention)

6. **Version file** — Is `version.rb` minimal (just the VERSION constant)?
   Flag version files that require other code.

---

### Phase 4: Dependency Review

Evaluate runtime and development dependencies.

**Check each item:**

1. **Runtime dependency count** — Zero is ideal. Each dependency is a liability.
   Flag gems with >3 runtime dependencies. For each dependency ask:
   could this be replaced with stdlib?

2. **Dependency version constraints** — Are constraints appropriately loose?
   - `~> 2.0` (good for libraries — allows 2.x)
   - `>= 2.0, < 4.0` (acceptable for broad compatibility)
   - `= 2.3.1` (problematic — causes version conflicts)

3. **Optional dependencies** — Does the gem handle missing optional deps gracefully?
   Pattern: `defined?(SomeGem)` checks or `begin; require "somegem"; rescue LoadError; end`

4. **Rails coupling** — Does the gem require Rails components directly, or use
   `ActiveSupport.on_load` and `defined?(Rails)` guards?
   Flag any `require "active_record"` or `require "action_controller"` at top level.

5. **Ruby version constraint** — Does the gemspec declare `required_ruby_version`?
   Is it reasonable (supports current and previous major)?

6. **Gemfile.lock** — Is it committed? (Should NOT be for gems, SHOULD be for apps.)

---

### Phase 5: Rails Integration Review

Skip if the gem has no Rails integration. Otherwise, evaluate safety.

**Check each item:**

1. **Railtie/Engine** — Is Rails integration isolated in a Railtie or Engine?
   Is it loaded conditionally with `if defined?(Rails)`?

2. **ActiveSupport.on_load** — Are hooks into Rails models, controllers, jobs
   deferred via `on_load` rather than eager `include`/`extend`?

3. **Namespace isolation** — If using an Engine, is `isolate_namespace` set?

4. **Migration safety** — If the gem provides migrations or generators:
   are they reversible? Do they use safe patterns for production (no `remove_column`
   without `safety_assured`)?

5. **Asset pipeline** — If the gem provides assets, does it support both Sprockets
   and Propshaft? Are assets namespaced?

6. **Configuration via Rails** — Does the gem support `config_for(:gemname)` for
   YAML-based configuration with ERB?

---

### Phase 6: Testability & Quality Review

Evaluate test architecture and code confidence.

**Check each item:**

1. **Test framework** — Minitest or RSpec? Either is acceptable. Flag no tests.

2. **Test isolation** — Can tests run without a network, database, or external service?
   Flag tests that require running services without documenting it.

3. **Multi-version testing** — Does the gem test against multiple Ruby versions?
   Multiple Rails versions (if Rails-integrated)? Check for Appraisal gemfiles
   or matrix CI configs.

4. **Test coverage distribution** — Are edge cases tested? Are error paths tested?
   Flag test suites that only test the happy path.

5. **Test helpers** — Does the test suite provide helpers for consumers to use
   in their own tests? (e.g., `GemName::TestHelper`, factory methods, mock adapters)

6. **CI configuration** — Is there a working CI setup? Does it test the matrix
   of supported Ruby/Rails versions?

---

### Phase 7: Extension & Evolution Review

Evaluate how well the gem handles change.

**Check each item:**

1. **Plugin/adapter pattern** — Can behavior be extended without modifying the gem?
   Does it support registering custom adapters, strategies, or backends?

2. **Callback/hook system** — Does the gem provide hooks for consumers to tap into
   the lifecycle? (e.g., `before_search`, `after_encrypt`)

3. **Semantic versioning** — Does the gem follow SemVer? Check CHANGELOG for
   evidence of breaking changes in minor versions.

4. **Deprecation strategy** — How does the gem handle deprecated features?
   Flag gems that remove features without deprecation warnings.

5. **Upgrade path** — For major version bumps, are migration guides provided?

6. **Documentation** — Is the README sufficient to use the gem without reading source?
   Does it cover: installation, quick start, configuration, common patterns, and errors?

---

## Producing the Review Report

After completing all phases, produce a structured report:

```markdown
# Gem Architecture Review: {gem_name} v{version}

## Summary Verdict

**Overall**: Ready for production / Needs work / Significant concerns

[2-3 sentence summary of the gem's architectural quality]

## Scores

| Area | Score | Notes |
|------|-------|-------|
| API Design | A-F | |
| Module Organization | A-F | |
| Dependencies | A-F | |
| Rails Integration | A-F or N/A | |
| Testability | A-F | |
| Extensibility | A-F | |

## Critical Issues
[Issues that must be fixed — security, thread safety, data loss]

## Important Issues
[Issues that should be fixed — API design, coupling, missing tests]

## Suggestions
[Improvements that would elevate the gem's quality]

## What's Done Well
[Positive patterns worth preserving or learning from]

## Recommended Actions
[Prioritized list of changes, ordered by impact]
```

## Anti-Patterns Checklist

Quick-reference for common gem architecture problems:

| Anti-Pattern | What to look for | Why it matters |
|---|---|---|
| **God module** | Entry point >200 lines, does config + logic + integration | Hard to test, hard to extend |
| **Require spaghetti** | Circular requires, load-order-dependent behavior | Breaks in unpredictable ways |
| **Rails assumption** | `require "active_record"` at top level | Gem unusable outside Rails |
| **Global state** | `@@class_variables`, mutable constants | Thread-unsafe, test pollution |
| **Leaky abstraction** | Internal classes in public API, undocumented `send` calls | Breaking changes on refactor |
| **Dependency bloat** | >3 runtime deps, or deps for things stdlib handles | Version conflicts, attack surface |
| **Missing errors** | `raise "something went wrong"` without custom class | Consumers can't rescue selectively |
| **Positional soup** | `def call(name, type, options, flag, format)` | Unreadable call sites |
| **Test coupling** | Tests require specific database, network, or file state | Can't run in CI or isolation |
| **Monkey-patching** | `class String; def fancy_method; end; end` | Conflicts with other gems |
| **Version lock** | `spec.add_dependency "foo", "= 1.2.3"` | Forces consumers into exact version |
| **Silent failure** | Swallowing exceptions, returning nil on error | Bugs hide until production |

## Reference Files

For detailed patterns and examples:
- **[references/decomposition-patterns.md](references/decomposition-patterns.md)** — Module decomposition strategies for large gems
- **[references/api-design-patterns.md](references/api-design-patterns.md)** — Public API design patterns from well-known gems
- **[references/dependency-evaluation.md](references/dependency-evaluation.md)** — Framework for evaluating gem dependencies
