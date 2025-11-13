# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-XX

### Added

- Initial release of SimpleFlow as a Ruby gem
- Core `Result` class with immutable value objects
- `Pipeline` class for sequential step execution
- `DagPipeline` class for dependency-based execution with parallel support
- `Step` and `ConditionalStep` classes for named, trackable steps
- `ExecutionError` class for structured error handling with severity levels
- Built-in middleware:
  - `Logging` - Log step execution
  - `Instrumentation` - Measure execution time and memory
  - `Retry` - Automatic retry with exponential backoff
- Pipeline composition via `>>` operator
- Conditional steps with `step_if` method
- Subgraph extraction from DAG pipelines
- DAG pipeline merging
- Circular dependency detection
- Comprehensive test suite with 80+ tests
- Full documentation with examples
- Three example files demonstrating usage:
  - `examples/basic_usage.rb`
  - `examples/dag_usage.rb`
  - `examples/middleware_usage.rb`

### Fixed

- **Critical**: Fixed immutability bug in `Result#halt` that was mutating the `@continue` instance variable
- Proper error handling in steps with automatic conversion to error results
- Thread-safe parallel execution in DAG pipelines

### Changed

- Refactored from monolithic files to proper gem structure
- Enhanced error handling with `ExecutionError` objects instead of plain strings
- Improved context tracking with step names automatically added
- Better middleware stacking with reverse application order

### Improved

- All results are now truly immutable (no state mutation)
- Named steps for better debugging and error messages
- Rich error objects with severity levels (warning, error, critical)
- Pipeline introspection methods (`size`, `step_names`, `find_step`)
- DAG execution with both serial and parallel modes
- Topological sorting for dependency resolution
- Parallel group calculation for optimal concurrency

## Roadmap

### [0.2.0] - Future

- [ ] Streaming/lazy evaluation support
- [ ] Step memoization for caching results
- [ ] Transaction/rollback support
- [ ] Plugin system for third-party middleware
- [ ] Performance profiling tools
- [ ] Visual pipeline graph generation
- [ ] Integration with popular Ruby frameworks (Rails, Sinatra)

### [0.3.0] - Future

- [ ] Distributed execution support
- [ ] Workflow persistence and recovery
- [ ] Real-time progress tracking
- [ ] Conditional branching (if/else paths)
- [ ] Loop constructs for iterative processing
- [ ] Sub-pipeline calls (nested workflows)

---

## Version History

- **0.1.0** (Initial Release) - Complete rewrite as a Ruby gem with DAG support, middleware, and enhanced features

## Migration from Original Implementation

If you were using the original workflow files, here's how to migrate:

### Before (Original)
```ruby
require_relative 'workflow/simple_flow'

pipeline = SimpleFlow::Pipeline.new do
  step ->(result) { result.continue(result.value + 1) }
end
```

### After (Gem)
```ruby
require 'simple_flow'

pipeline = SimpleFlow::Pipeline.new do
  step :increment, ->(result) { result.continue(result.value + 1) }
end
```

### Key Changes

1. **Named Steps Required** - All steps must now have a name (first parameter)
2. **Structured Errors** - Use `with_error(key, message, severity:)` instead of plain hash
3. **Immutable Results** - `halt()` now returns a new instance (bug fix)
4. **Middleware Namespace** - `SimpleFlow::MiddleWare` → `SimpleFlow::Middleware`

See the [README](README.md) for complete migration guide and examples.
