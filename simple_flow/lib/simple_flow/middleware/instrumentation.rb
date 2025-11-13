# frozen_string_literal: true

module SimpleFlow
  module Middleware
    ##
    # Instrumentation middleware that measures step execution time
    #
    class Instrumentation
      # @param callable [#call] the step to wrap
      # @param collector [#record, nil] custom metrics collector
      # @param api_key [String, nil] API key for external service
      def initialize(callable, collector: nil, api_key: nil)
        @callable = callable
        @collector = collector
        @api_key = api_key
      end

      def call(result)
        step_name = result.context[:current_step] || 'unknown'
        start_time = Time.now
        start_memory = memory_usage

        result = @callable.call(result)

        duration = Time.now - start_time
        memory_delta = memory_usage - start_memory

        # Record metrics
        metrics = {
          step: step_name,
          duration: duration,
          memory_delta: memory_delta,
          success: result.continue?,
          timestamp: start_time
        }

        if @collector
          @collector.record(metrics)
        else
          log_metrics(step_name, duration, memory_delta)
        end

        # Add metrics to result context
        result
          .with_context(:"#{step_name}_duration", duration)
          .with_context(:"#{step_name}_memory_delta", memory_delta)
      end

      private

      def memory_usage
        # Returns allocated objects count as a proxy for memory usage
        GC.stat[:total_allocated_objects]
      rescue StandardError
        0
      end

      def log_metrics(step_name, duration, memory_delta)
        msg = "Instrumentation [#{@api_key}]: #{step_name} took #{duration.round(4)}s"
        msg += " (memory delta: #{memory_delta} objects)" if memory_delta > 0
        puts msg
      end
    end
  end
end
