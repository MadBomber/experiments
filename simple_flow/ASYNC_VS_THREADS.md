# Async Gem vs Threads for SimpleFlow

## Executive Summary

For **I/O-bound workflows**, the `async` gem would provide substantial benefits over native threads:

- ✅ **10-100x lighter weight** (fibers vs threads)
- ✅ **No race conditions** (cooperative vs preemptive)
- ✅ **Higher concurrency** (thousands vs dozens)
- ✅ **No GIL contention** (single-threaded)
- ⚠️ **Requires async ecosystem** (async-http, async-postgres, etc.)

## Detailed Comparison

### Architecture Differences

#### Current (Native Threads)
```ruby
# Preemptive multitasking - OS schedules thread switches
Thread.new do
  response = HTTP.get("https://api.example.com")  # Thread blocks here
  process(response)
end

# Issues:
# - Thread stack: ~1MB per thread
# - Context switching overhead
# - Race conditions on shared state
# - GIL contention in MRI Ruby
```

#### With Async Gem
```ruby
# Cooperative multitasking - yields control at I/O points
Async do
  response = Async::HTTP.get("https://api.example.com")  # Yields to other fibers
  process(response)
end

# Benefits:
# - Fiber stack: ~4KB per fiber
# - No context switching overhead
# - No race conditions (single-threaded)
# - No GIL issues
```

### Performance Comparison

#### Concurrency Limits

| Approach | Max Concurrent | Memory/Unit | Scheduling |
|----------|---------------|-------------|------------|
| Native Threads | ~100-200 | ~1 MB | Preemptive (OS) |
| Async Fibers | ~10,000+ | ~4 KB | Cooperative (Ruby) |

#### Real-World Example: 100 HTTP Requests

**Native Threads:**
```
Memory: 100 threads × 1 MB = 100 MB
Time: Limited by thread pool size
Context switches: High overhead
```

**Async Fibers:**
```
Memory: 100 fibers × 4 KB = 400 KB (250x less!)
Time: All concurrent if I/O bound
Context switches: Minimal overhead
```

### Thread Safety

#### Current Implementation Issues

```ruby
# RACE CONDITION with threads
dag = DagPipeline.new do
  step :init, ->(r) { r.continue({ total: 0 }) }

  step :add_a, ->(r) {
    r.value[:total] += 100  # Thread A
    r.continue(r.value)
  }, depends_on: :init

  step :add_b, ->(r) {
    r.value[:total] += 200  # Thread B - RACE!
    r.continue(r.value)
  }, depends_on: :init
end

# Result: Undefined (100, 200, or 300)
```

#### With Async (No Race Conditions!)

```ruby
# NO RACE CONDITION - single-threaded
dag = AsyncDagPipeline.new do
  step :init, ->(r) { r.continue({ total: 0 }) }

  step :add_a, ->(r) {
    r.value[:total] += 100  # Runs to completion
    r.continue(r.value)
  }, depends_on: :init

  step :add_b, ->(r) {
    r.value[:total] += 200  # Runs after context switch
    r.continue(r.value)
  }, depends_on: :init
end

# Result: Always 300 (deterministic if steps don't yield)
# But note: If add_a yields during execution, add_b could interleave
```

**Important caveat**: While fibers are single-threaded, they can still interleave if they yield control during execution. However, they only yield at explicit async points, making reasoning about concurrency much easier.

## Proposed Implementation

### 1. Async-Compatible Result (No Changes Needed!)

Since fibers are single-threaded within an async task, we don't need deep cloning:

```ruby
# Current Result class works fine with async!
# No race conditions because fibers don't preempt mid-operation
```

### 2. Async DAG Pipeline

```ruby
require 'async'
require 'async/barrier'

module SimpleFlow
  class AsyncDagPipeline < Pipeline
    # Execute with async/await pattern
    def call_async(result)
      Sync do
        execution_order = sorted_steps
        execute_steps_async(result, execution_order)
      end
    end

    # Execute with maximum concurrency
    def call_parallel_async(result)
      Sync do
        execution_groups = parallel_groups
        execute_groups_async(result, execution_groups)
      end
    end

    private

    def execute_groups_async(result, execution_groups)
      results_by_step = {}

      execution_groups.each do |group|
        break unless result.continue?

        if group.size == 1
          # Single step, execute directly
          step_name = group.first
          step = find_step(step_name)
          if step
            result = merge_dependency_results(result, step_name, results_by_step)
            result = step.call(result)
            results_by_step[step_name] = result
          end
        else
          # Multiple steps - execute concurrently with async
          barrier = Async::Barrier.new
          group_results = {}

          group.each do |step_name|
            step = find_step(step_name)
            next unless step

            barrier.async do
              step_result = merge_dependency_results(result, step_name, results_by_step)
              step_result = step.call(step_result)
              group_results[step_name] = step_result
            end
          end

          # Wait for all concurrent tasks
          barrier.wait

          # Merge results
          result = merge_parallel_results(result, group_results)
          results_by_step.merge!(group_results)
        end
      end

      result
    end
  end
end
```

### 3. Async-Aware Steps

```ruby
module SimpleFlow
  class AsyncStep < Step
    def initialize(name, callable, **options)
      super
      @async = options[:async] || false
    end

    def call(result)
      result = result.with_context(:current_step, @name)

      if @async
        # This step does async I/O
        Async do |task|
          execute_with_timeout(result, task)
        end.wait
      else
        # Regular synchronous step
        execute_callable(result)
      end
    end

    private

    def execute_with_timeout(result, task)
      if @timeout
        task.with_timeout(@timeout) do
          @callable.call(result)
        end
      else
        @callable.call(result)
      end
    rescue Async::TimeoutError
      result.halt.with_error(
        :timeout,
        "#{@name}: Timed out after #{@timeout}s",
        severity: :critical
      )
    end
  end
end
```

### 4. Usage Example

```ruby
require 'async'
require 'async/http/internet'

# Define async pipeline
pipeline = SimpleFlow::AsyncDagPipeline.new do
  step :init, ->(r) {
    r.continue({ user_id: r.value })
  }

  # These steps use async I/O
  step :fetch_profile, ->(r) {
    Async do
      internet = Async::HTTP::Internet.new
      response = internet.get("https://api.example.com/users/#{r.value[:user_id]}")
      r.with_context(:profile, response.read).continue(r.value)
    end.wait
  }, depends_on: :init, async: true

  step :fetch_posts, ->(r) {
    Async do
      internet = Async::HTTP::Internet.new
      response = internet.get("https://api.example.com/posts?user=#{r.value[:user_id]}")
      r.with_context(:posts, response.read).continue(r.value)
    end.wait
  }, depends_on: :init, async: true

  step :fetch_comments, ->(r) {
    Async do
      internet = Async::HTTP::Internet.new
      response = internet.get("https://api.example.com/comments?user=#{r.value[:user_id]}")
      r.with_context(:comments, response.read).continue(r.value)
    end.wait
  }, depends_on: :init, async: true

  step :combine, ->(r) {
    profile = r.context[:fetch_profile_profile]
    posts = r.context[:fetch_posts_posts]
    comments = r.context[:fetch_comments_comments]

    r.continue({
      profile: profile,
      posts: posts,
      comments: comments
    })
  }, depends_on: [:fetch_profile, :fetch_posts, :fetch_comments]
end

# Execute with maximum concurrency
result = pipeline.call_parallel_async(SimpleFlow::Result.new(123))
```

### 5. Benchmark Comparison

```ruby
require 'benchmark'
require 'async'
require 'async/http/internet'

def fetch_url_thread(url)
  require 'net/http'
  Net::HTTP.get(URI(url))
end

def fetch_url_async(url)
  Async do
    internet = Async::HTTP::Internet.new
    response = internet.get(url)
    response.read
  end.wait
end

urls = 100.times.map { |i| "https://httpbin.org/delay/1" }

Benchmark.bm(20) do |x|
  x.report("Threads (10 max):") do
    threads = []
    urls.each_slice(10) do |batch|
      batch_threads = batch.map { |url| Thread.new { fetch_url_thread(url) } }
      batch_threads.each(&:join)
      threads.concat(batch_threads)
    end
  end
  # Expected: ~100 seconds (10 batches of 10 concurrent requests)

  x.report("Async (unlimited):") do
    Async do
      barrier = Async::Barrier.new
      urls.each { |url| barrier.async { fetch_url_async(url) } }
      barrier.wait
    end
  end
  # Expected: ~1-2 seconds (all 100 requests concurrent)
end
```

**Expected Results:**
```
                          user     system      total        real
Threads (10 max):     0.234000   0.567000   0.801000 (100.456789)
Async (unlimited):    0.089000   0.045000   0.134000 (  1.234567)
```

**80-100x faster for I/O-bound work!**

## Advantages of Async for SimpleFlow

### 1. ✅ No Deep Cloning Needed

**Problem with threads:**
```ruby
# Threads need deep cloning to avoid race conditions
def dup
  self.class.new(
    deep_clone(@value),  # Expensive!
    ...
  )
end
```

**Solution with async:**
```ruby
# Fibers are single-threaded - no cloning needed!
def dup
  self.class.new(
    @value,  # Safe - no concurrent access
    ...
  )
end
```

### 2. ✅ Massive Concurrency

- **Threads**: Limited to ~100-200 concurrent operations
- **Async**: Can handle 10,000+ concurrent operations

Perfect for:
- Bulk API requests
- Parallel database queries
- Concurrent file operations
- Microservice fan-out

### 3. ✅ Deterministic Execution

Fibers yield at predictable points (I/O operations), making behavior more predictable than preemptive threading.

### 4. ✅ Lower Memory Footprint

```
1000 concurrent operations:
- Threads: ~1 GB memory
- Async:   ~4 MB memory
```

### 5. ✅ Better Error Handling

```ruby
Async do |task|
  # Structured concurrency - child tasks tied to parent
  task.async { step_a }
  task.async { step_b }

  # If parent scope exits, all children are cancelled
  # No orphaned tasks!
end
```

## Disadvantages / Considerations

### 1. ⚠️ Requires Async Ecosystem

**Standard library won't work:**
```ruby
# ❌ These will BLOCK the reactor:
Net::HTTP.get(uri)
File.read("file.txt")
sleep(1)

# ✅ Need async alternatives:
Async::HTTP::Internet.new.get(url)
Async::IO.open("file.txt", &:read)
task.sleep(1)
```

**Async ecosystem:**
- `async-http` - HTTP client
- `async-postgres` - PostgreSQL
- `async-redis` - Redis
- `async-io` - File I/O
- Many more...

### 2. ⚠️ Breaking API Change

Current steps are blocking:
```ruby
step :fetch, ->(result) {
  response = HTTP.get(url)  # Blocking
  result.continue(response)
}
```

Would need async-aware:
```ruby
step :fetch, ->(result) {
  Async do
    response = Async::HTTP.get(url)  # Non-blocking
    result.continue(response)
  end.wait
}
```

### 3. ⚠️ Learning Curve

Users need to understand:
- Fiber-based concurrency
- When to use `Async { }` blocks
- Reactor pattern
- Structured concurrency

### 4. ⚠️ Mixed Blocking/Async Code

If a step blocks without yielding:
```ruby
step :cpu_intensive, ->(r) {
  result = heavy_computation()  # Blocks entire reactor!
  r.continue(result)
}
```

All other concurrent tasks are blocked.

**Solution**: Offload to thread pool:
```ruby
step :cpu_intensive, ->(r) {
  result = Async do |task|
    task.async(annotation: "CPU Work") do
      Thread.pool.async do
        heavy_computation()
      end.wait
    end
  end.wait
  r.continue(result)
}
```

## Recommendation: Hybrid Approach

### Option 1: Add Async as Alternative Backend

Keep thread-based implementation, add async option:

```ruby
# Thread-based (current)
pipeline.call_parallel(result, max_threads: 4)

# Async-based (new)
pipeline.call_async(result)
```

**Pros:**
- Backward compatible
- Users can choose based on use case
- Both implementations share same Pipeline DSL

**Cons:**
- Maintain two execution engines
- API confusion

### Option 2: Async by Default with Thread Fallback

Make async the default for I/O operations:

```ruby
# Automatically detects I/O operations
pipeline = SimpleFlow::DagPipeline.new do
  step :fetch, ->(r) {
    # Automatically runs in async context if using async-compatible libraries
    response = Async::HTTP.get(url)
    r.continue(response)
  }

  step :compute, ->(r) {
    # Automatically offloads to thread if blocking
    result = heavy_computation()
    r.continue(result)
  }
end
```

**Pros:**
- Best of both worlds
- Transparent optimization

**Cons:**
- Complex implementation
- Hard to detect blocking vs non-blocking

### Option 3: Explicit Async Pipeline Type

Create separate `AsyncDagPipeline`:

```ruby
# For I/O-bound work
async_pipeline = SimpleFlow::AsyncDagPipeline.new do
  step :fetch_a, ->(r) { async_http_call }
  step :fetch_b, ->(r) { async_db_query }
end

# For CPU-bound work
thread_pipeline = SimpleFlow::DagPipeline.new do
  step :process_a, ->(r) { cpu_intensive_work }
  step :process_b, ->(r) { more_cpu_work }
end
```

**Pros:**
- Clear intent
- Optimal for each use case
- No API confusion

**Cons:**
- Duplicate code
- Users need to choose upfront

## Recommended Implementation Plan

### Phase 1: Add AsyncDagPipeline (New Class)

```ruby
# simple_flow.gemspec
spec.add_dependency "async", "~> 2.0"
spec.add_dependency "async-http", "~> 0.60"
```

```ruby
# lib/simple_flow/async_dag_pipeline.rb
module SimpleFlow
  class AsyncDagPipeline < Pipeline
    # Implementation using Async::Barrier
  end
end
```

### Phase 2: Update Documentation

Show when to use each:

```ruby
# Use AsyncDagPipeline for:
✅ HTTP API calls
✅ Database queries (with async-postgres)
✅ File I/O (with async-io)
✅ Redis operations (with async-redis)

# Use DagPipeline (threads) for:
✅ CPU-intensive processing
✅ Existing blocking libraries
✅ Simple workflows (< 10 concurrent ops)
```

### Phase 3: Add Examples

```ruby
# examples/async_api_fanout.rb
# examples/async_database_queries.rb
# examples/mixed_async_threading.rb
```

## Conclusion

**For I/O-bound workflows, async is a clear winner:**

| Metric | Threads | Async | Winner |
|--------|---------|-------|--------|
| Max Concurrency | ~100 | ~10,000 | 🏆 Async |
| Memory/Op | 1 MB | 4 KB | 🏆 Async |
| Race Conditions | Yes | No* | 🏆 Async |
| Thread Safety | Complex | Simple | 🏆 Async |
| Performance (I/O) | Good | Excellent | 🏆 Async |
| Performance (CPU) | Good | Poor | 🏆 Threads |
| Ecosystem | Everything | Limited | 🏆 Threads |
| Learning Curve | Low | Medium | 🏆 Threads |

*Async fibers can still interleave, but only at explicit yield points

**Recommendation**: Implement `AsyncDagPipeline` as optional alternative for I/O-heavy workflows, keep thread-based implementation for CPU-bound and blocking operations.

This gives users the best of both worlds! 🎯
