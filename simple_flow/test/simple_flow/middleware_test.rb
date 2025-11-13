# frozen_string_literal: true

require "test_helper"
require "stringio"

module SimpleFlow
  module Middleware
    class MiddlewareTest < Minitest::Test
      def setup
        @result = Result.new(42)
        @step = ->(result) { result.continue(result.value * 2) }
      end

      def test_logging_middleware
        output = StringIO.new
        logger = Logger.new(output)
        logger.level = Logger::INFO

        middleware = Logging.new(@step, logger: logger, level: :info)
        result = middleware.call(@result.with_context(:current_step, :test_step))

        assert_equal 84, result.value
        log_output = output.string
        assert_includes log_output, "Starting step: test_step"
        assert_includes log_output, "Completed step: test_step"
      end

      def test_instrumentation_middleware
        output = StringIO.new
        $stdout = output

        middleware = Instrumentation.new(@step, api_key: "test_key")
        result = middleware.call(@result.with_context(:current_step, :test_step))

        $stdout = STDOUT

        assert_equal 84, result.value
        assert result.context.key?(:test_step_duration)
        assert result.context.key?(:test_step_memory_delta)
        assert_includes output.string, "Instrumentation [test_key]: test_step took"
      end

      def test_retry_middleware_success
        attempts = 0
        flaky_step = ->(result) {
          attempts += 1
          raise StandardError, "Temporary error" if attempts < 2
          result.continue(result.value * 2)
        }

        middleware = Retry.new(flaky_step, max_attempts: 3, backoff: 0.01)
        result = middleware.call(@result)

        assert_equal 84, result.value
        assert_equal 2, attempts
      end

      def test_retry_middleware_exhausted
        step_that_always_fails = ->(_result) {
          raise StandardError, "Permanent error"
        }

        middleware = Retry.new(step_that_always_fails, max_attempts: 3, backoff: 0.01)
        result = middleware.call(@result)

        refute result.continue?
        assert result.errors.key?(:retry_exhausted)
        assert_equal 3, result.context[:retry_attempts]
      end

      def test_retry_middleware_callback
        retry_count = 0
        on_retry = ->(result, attempt, error) {
          retry_count = attempt
        }

        flaky_step = ->(result) {
          raise StandardError, "Error" if retry_count < 2
          result.continue(result.value)
        }

        middleware = Retry.new(flaky_step, max_attempts: 3, backoff: 0.01, on_retry: on_retry)
        result = middleware.call(@result)

        assert result.success?
        assert_equal 2, retry_count
      end

      def test_middleware_stacking
        pipeline = Pipeline.new do
          use_middleware Instrumentation, api_key: "test"
          use_middleware Retry, max_attempts: 2, backoff: 0.01

          step :test, ->(result) { result.continue(result.value + 1) }
        end

        result = pipeline.call(Result.new(10))

        assert_equal 11, result.value
        assert result.context.key?(:test_duration)
      end
    end
  end
end
