# SimpleFlow Concurrency Analysis & Recommendations

## Current Implementation

### Architecture
- **Model**: Ruby native threads with mutex-based synchronization
- **Strategy**: Wave-based parallel execution of independent DAG steps
- **Thread Safety**: Mutex-protected result collection, immutable result objects

### How It Works

1. **Dependency Analysis**: `parallel_groups()` calculates execution waves
2. **Wave Execution**: Each wave runs serially, but steps within a wave run in parallel
3. **Result Isolation**: Each thread gets `result.dup` to avoid conflicts
4. **Result Merging**: After all threads complete, results merge into single output

## Issues & Limitations

### 🔴 Critical: Shallow Duplication

**Location**: `lib/simple_flow/result.rb:184`

```ruby
def dup
  self.class.new(
    @value,              # ⚠️ NOT duplicated - shared reference!
    context: @context.dup,
    errors: @errors.dup,
    continue: @continue
  )
end
```

**Problem**: If `@value` is a mutable object (Hash, Array, custom object), all parallel threads share the same instance.

**Race Condition Example**:
```ruby
dag = SimpleFlow::DagPipeline.new do
  step :init, ->(r) { r.continue({ total: 0 }) }  # Hash value

  step :add_a, ->(r) {
    r.value[:total] += 100  # Thread A modifies shared hash
    r.continue(r.value)
  }, depends_on: :init

  step :add_b, ->(r) {
    r.value[:total] += 200  # Thread B modifies shared hash
    r.continue(r.value)
  }, depends_on: :init
end

# Result: Undefined! Could be 100, 200, or 300 depending on interleaving
```

**Fix Options**:

1. **Deep Clone with Marshal** (slow but safe):
```ruby
def dup
  self.class.new(
    deep_dup(@value),
    context: @context.dup,
    errors: @errors.dup,
    continue: @continue
  )
end

private

def deep_dup(obj)
  Marshal.load(Marshal.dump(obj))
rescue TypeError
  obj.dup rescue obj  # Fallback for non-serializable objects
end
```

2. **Freeze Values** (prevent mutation):
```ruby
def initialize(value, context: {}, errors: {}, continue: true)
  @value = deep_freeze(value)
  @context = context.freeze
  @errors = errors.freeze
  @continue = continue
end

def deep_freeze(obj)
  obj.freeze
  case obj
  when Hash then obj.each_value { |v| deep_freeze(v) }
  when Array then obj.each { |v| deep_freeze(v) }
  end
  obj
end
```

3. **Document Immutability Requirement**:
```ruby
# Users must ensure values are immutable or use frozen objects
result.continue([1, 2, 3].freeze)
result.continue({ key: "value" }.freeze)
```

### 🟡 Medium: Thread Pool Absence

**Location**: `lib/simple_flow/dag_pipeline.rb:256-278`

**Issue**: Creates new threads for each parallel group
- Thread creation overhead (~1-2ms per thread)
- No thread reuse
- GC pressure from thread objects

**Recommended**: Use `concurrent-ruby` gem:
```ruby
require 'concurrent'

def execute_steps_parallel(result, execution_groups, max_threads)
  pool = Concurrent::FixedThreadPool.new(max_threads)

  execution_groups.each do |group|
    next if group.size == 1

    promises = group.map { |step_name|
      Concurrent::Promise.execute(executor: pool) {
        thread_result = result.dup
        step.call(thread_result)
      }
    }

    thread_results = promises.map(&:value!)  # Wait for all
    result = merge_parallel_results(result, thread_results)
  end

  pool.shutdown
  pool.wait_for_termination
end
```

### 🟡 Medium: Incorrect Thread Limiting

**Location**: `lib/simple_flow/dag_pipeline.rb:274-277`

```ruby
if threads.size >= max_threads
  threads.shift.join  # Only waits for ONE thread
end
```

**Problem**: If `max_threads=4` and `group.size=10`:
- Spawns 4 threads
- On 5th iteration, waits for 1st thread, spawns 5th (4 running)
- On 6th iteration, waits for 2nd thread, spawns 6th (4 running)
- Pattern continues, but at any moment only ~4 threads active

Actually this IS correct behavior for sliding window, but could be clearer!

**Better Implementation**:
```ruby
# Batch processing
group.each_slice(max_threads) do |batch|
  threads = batch.map { |step_name| Thread.new { ... } }
  threads.each(&:join)
end
```

### 🟡 Medium: GIL Limitations (MRI Ruby)

**Problem**: MRI Ruby has a Global Interpreter Lock (GIL)
- Only ONE thread executes Ruby code at a time
- Parallelism only helps for:
  - **I/O operations** (network, disk, database)
  - **C extensions** that release GIL
  - **Sleep/wait operations**

**CPU-bound work gets NO speedup** (actually slower due to thread overhead).

**Solutions**:
1. Use **JRuby** or **TruffleRuby** (no GIL)
2. Use **Ractor** (Ruby 3.0+) for true parallelism
3. Use **Process-based parallelism** for CPU-bound work

**Process-Based Alternative**:
```ruby
def execute_steps_parallel_forked(result, execution_groups, max_processes)
  require 'parallel'

  execution_groups.each do |group|
    next if group.size == 1

    results = Parallel.map(group, in_processes: max_processes) do |step_name|
      step = find_step(step_name)
      thread_result = result.dup
      [step_name, step.call(thread_result)]
    end

    result = merge_parallel_results(result, results.to_h)
  end
end
```

### 🟢 Minor: No Timeout Handling

**Issue**: If a step hangs, the entire pipeline hangs

**Recommendation**:
```ruby
require 'timeout'

threads << Thread.new do
  Timeout.timeout(step_timeout || 30) do
    thread_result = step.call(thread_result)
  end
rescue Timeout::Error
  thread_result.halt.with_error(:timeout, "Step timed out", severity: :critical)
end
```

### 🟢 Minor: No Progress Tracking

For long-running pipelines, no way to monitor progress.

**Recommendation**: Add callback hooks:
```ruby
dag.call_parallel(result,
  on_step_start: ->(step_name) { puts "Starting #{step_name}" },
  on_step_complete: ->(step_name, result) { puts "Completed #{step_name}" }
)
```

## Recommended Improvements

### Priority 1: Fix Value Duplication

```ruby
# lib/simple_flow/result.rb
def dup
  self.class.new(
    deep_dup_value(@value),
    context: @context.dup,
    errors: @errors.dup,
    continue: @continue
  )
end

private

def deep_dup_value(obj)
  case obj
  when Hash
    obj.transform_keys { |k| deep_dup_value(k) }
       .transform_values { |v| deep_dup_value(v) }
  when Array
    obj.map { |item| deep_dup_value(item) }
  when String, Symbol, Numeric, TrueClass, FalseClass, NilClass
    obj  # Immutable, no need to dup
  else
    # For custom objects, try dup, fallback to original
    obj.dup rescue obj
  end
end
```

### Priority 2: Add `concurrent-ruby` Dependency

```ruby
# simple_flow.gemspec
spec.add_dependency "concurrent-ruby", "~> 1.2"
```

```ruby
# lib/simple_flow/dag_pipeline.rb
require 'concurrent'

def execute_steps_parallel(result, execution_groups, max_threads)
  pool = Concurrent::FixedThreadPool.new(max_threads)
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
      # Multiple steps, execute in parallel using thread pool
      futures = {}

      group.each do |step_name|
        step = find_step(step_name)
        next unless step

        futures[step_name] = Concurrent::Future.execute(executor: pool) do
          thread_result = merge_dependency_results(result.dup, step_name, results_by_step)
          step.call(thread_result)
        end
      end

      # Wait for all futures and collect results
      thread_results = futures.transform_values(&:value!)
      result = merge_parallel_results(result, thread_results)
      results_by_step.merge!(thread_results)
    end
  end

  pool.shutdown
  pool.wait_for_termination
  result
end
```

### Priority 3: Add Timeout Support

```ruby
# lib/simple_flow/step.rb
class Step
  def initialize(name, callable, timeout: nil, **options)
    @name = name
    @callable = callable
    @timeout = timeout
    @options = options
  end

  def call(result)
    result = result.with_context(:current_step, @name)

    if @timeout
      Timeout.timeout(@timeout) do
        execute_callable(result)
      end
    else
      execute_callable(result)
    end
  rescue Timeout::Error
    result.halt.with_error(
      :timeout,
      "#{@name}: Execution timed out after #{@timeout}s",
      severity: :critical
    )
  rescue StandardError => e
    result.halt.with_error(
      :step_error,
      "#{@name}: #{e.message}",
      severity: :critical,
      exception: e
    )
  end

  private

  def execute_callable(result)
    start_time = Time.now if @options[:track_duration]
    output = @callable.call(result)

    if @options[:track_duration]
      duration = Time.now - start_time
      output = output.with_context(:"#{@name}_duration", duration)
    end

    output
  end
end
```

### Priority 4: Document Concurrency Model

Add to README.md:

```markdown
## Concurrency Model

### Thread Safety

SimpleFlow uses Ruby native threads for parallel execution in DAG pipelines.
The framework ensures thread safety through:

1. **Immutable Results**: Each thread receives a deep copy of the result
2. **Mutex Protection**: Shared state is protected by mutex locks
3. **Wave-Based Execution**: Only independent steps run concurrently

### Important Notes

#### GIL Limitations (MRI Ruby)

MRI Ruby's Global Interpreter Lock (GIL) means parallel execution only
benefits **I/O-bound operations**:

✅ **Benefits from parallelism:**
- HTTP requests
- Database queries
- File I/O
- External API calls

❌ **No benefit (CPU-bound):**
- Heavy computation
- Data processing
- Cryptography
- Image/video processing

For CPU-bound parallelism, use:
- **JRuby** or **TruffleRuby** (no GIL)
- **Process-based parallelism** (separate Ruby processes)

#### Value Immutability

**IMPORTANT**: Values passed through pipelines should be immutable or
thread-safe:

```ruby
# ✅ Good - immutable values
result.continue(42)
result.continue("string".freeze)
result.continue([1, 2, 3].freeze)

# ❌ Bad - mutable values in parallel steps
dag.new do
  step :root, ->(r) { r.continue([]) }  # Empty array
  step :a, ->(r) { r.value << 'A'; r.continue(r.value) }, depends_on: :root
  step :b, ->(r) { r.value << 'B'; r.continue(r.value) }, depends_on: :root
  # Race condition! Both threads modify the same array
end
```

### Performance Tips

1. **Use for I/O-bound work**: Best suited for parallel HTTP requests, DB queries
2. **Limit max_threads**: Default is 4, adjust based on your workload
3. **Profile before optimizing**: Serial execution may be faster for small pipelines
4. **Consider alternatives**: For CPU-bound work, use process-based parallelism
```

## Benchmarking

To verify the implementation, add benchmarks:

```ruby
# benchmark/dag_parallel_benchmark.rb
require 'benchmark'
require_relative '../lib/simple_flow'

# I/O-bound simulation
dag = SimpleFlow::DagPipeline.new do
  step :root, ->(r) { r.continue(r.value) }

  (1..10).each do |i|
    step :"task_#{i}", ->(r) {
      sleep 0.1  # Simulate I/O
      r.continue(r.value + 1)
    }, depends_on: :root
  end

  step :merge, ->(r) { r.continue(r.value) },
    depends_on: (1..10).map { |i| :"task_#{i}" }
end

result = SimpleFlow::Result.new(0)

Benchmark.bm(20) do |x|
  x.report("Serial execution:") { dag.call(result) }
  x.report("Parallel (2 threads):") { dag.call_parallel(result, max_threads: 2) }
  x.report("Parallel (4 threads):") { dag.call_parallel(result, max_threads: 4) }
  x.report("Parallel (10 threads):") { dag.call_parallel(result, max_threads: 10) }
end
```

Expected results:
```
                           user     system      total        real
Serial execution:      0.000234   0.000089   0.000323 (  1.004567)
Parallel (2 threads):  0.003456   0.001234   0.004690 (  0.506789)
Parallel (4 threads):  0.004567   0.001890   0.006457 (  0.305678)
Parallel (10 threads): 0.005678   0.002345   0.008023 (  0.204567)
```
