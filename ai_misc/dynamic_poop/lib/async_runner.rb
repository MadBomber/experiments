# frozen_string_literal: true

# Fiber-based concurrent task runner for the terrarium simulation.
# Uses the async gem when available; degrades to synchronous execution otherwise.
#
# Provides:
#   map_concurrent   — parallel robot ticks via Async::Barrier
#   submit/collect   — fire-and-forget background fibers for LLM calls
#   async_sleep      — fiber-aware sleep that yields to the reactor
#   shutdown         — clean stop of all background tasks
class AsyncRunner
  def initialize
    @background = {}
    @mutex      = Mutex.new
    @async_available = defined?(Async) && defined?(Async::Barrier)
    LOGGER.info("AsyncRunner: async gem #{@async_available ? 'available' : 'unavailable'}")
  end

  def async_available?
    @async_available
  end

  # Run block for each item concurrently (via Async::Barrier) or sequentially.
  # Returns array of results in the same order as items.
  def map_concurrent(items, &block)
    return items.map(&block) unless @async_available && inside_reactor?

    barrier = Async::Barrier.new
    results = Array.new(items.size)

    items.each_with_index do |item, idx|
      barrier.async do
        results[idx] = block.call(item)
      end
    end

    barrier.wait
    results
  ensure
    barrier&.stop
  end

  # Fire-and-forget: start a background fiber keyed by `key`.
  # Returns the previous completed result if one exists, otherwise nil.
  #
  # Lifecycle:
  #   1. No entry        → spawn task, return nil
  #   2. Entry running   → return nil (still pending)
  #   3. Entry finished  → return result, spawn new task
  def submit(key, &block)
    @mutex.synchronize do
      entry = @background[key]

      if entry.nil?
        spawn_background(key, &block)
        return nil
      end

      if entry[:done]
        result = entry[:result]
        spawn_background(key, &block)
        return result
      end

      nil # still running
    end
  end

  # Peek at a completed result without restarting the task.
  # Returns the result if done, nil otherwise.
  def collect(key)
    @mutex.synchronize do
      entry = @background[key]
      return nil unless entry&.dig(:done)

      entry[:result]
    end
  end

  # Is a background task still running for this key?
  def pending?(key)
    @mutex.synchronize do
      entry = @background[key]
      entry && !entry[:done]
    end
  end

  # Number of background tasks currently in-flight.
  def pending_count
    @mutex.synchronize do
      @background.count { |_k, v| !v[:done] }
    end
  end

  # Fiber-aware sleep: yields to the reactor so other fibers can run.
  # Falls back to Kernel.sleep when not inside a reactor.
  def async_sleep(seconds)
    if @async_available && inside_reactor?
      Async::Task.current.sleep(seconds)
    else
      Kernel.sleep(seconds)
    end
  end

  # Stop all background tasks cleanly.
  def shutdown
    @mutex.synchronize do
      @background.each_value do |entry|
        entry[:task]&.stop if entry[:task].respond_to?(:stop)
      end
      @background.clear
    end
    LOGGER.info("AsyncRunner: shutdown complete")
  end

  private

  def inside_reactor?
    Async::Task.current? rescue false
  end

  def spawn_background(key, &block)
    unless @async_available && inside_reactor?
      # Synchronous fallback: run immediately, store result
      result = begin
        block.call
      rescue => e
        LOGGER.error("AsyncRunner sync fallback error [#{key}]: #{e.message}")
        nil
      end
      @background[key] = { done: true, result: result, task: nil }
      return
    end

    task = Async::Task.current.async(transient: true) do
      result = begin
        block.call
      rescue => e
        LOGGER.error("AsyncRunner background error [#{key}]: #{e.message}")
        nil
      end

      @mutex.synchronize do
        @background[key] = { done: true, result: result, task: nil }
      end
    end

    @background[key] = { done: false, result: nil, task: task }
  end
end
