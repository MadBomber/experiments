# frozen_string_literal: true

module SimpleFlow
  module Middleware
    ##
    # Retry middleware with exponential backoff
    #
    # Automatically retries failed steps with configurable backoff strategy
    #
    # @example Usage
    #   use_middleware SimpleFlow::Middleware::Retry, max_attempts: 3, backoff: 2
    #
    class Retry
      DEFAULT_MAX_ATTEMPTS = 3
      DEFAULT_BACKOFF = 2
      DEFAULT_RETRYABLE_ERRORS = [StandardError].freeze

      attr_reader :max_attempts, :backoff, :retryable_errors

      # @param callable [#call] the step to wrap
      # @param max_attempts [Integer] maximum retry attempts
      # @param backoff [Numeric] exponential backoff base (seconds)
      # @param retryable_errors [Array<Class>] error classes to retry on
      # @param on_retry [Proc, nil] callback called before each retry
      def initialize(callable, max_attempts: DEFAULT_MAX_ATTEMPTS, backoff: DEFAULT_BACKOFF,
                     retryable_errors: DEFAULT_RETRYABLE_ERRORS, on_retry: nil)
        @callable = callable
        @max_attempts = max_attempts
        @backoff = backoff
        @retryable_errors = retryable_errors
        @on_retry = on_retry
      end

      def call(result)
        attempt = 0

        begin
          attempt += 1
          @callable.call(result)
        rescue *@retryable_errors => e
          if attempt < @max_attempts
            sleep_time = calculate_backoff(attempt)
            @on_retry&.call(result, attempt, e)
            sleep(sleep_time)
            retry
          else
            # Max attempts reached, return halted result with error
            result
              .halt
              .with_error(
                :retry_exhausted,
                "Failed after #{@max_attempts} attempts: #{e.message}",
                severity: :critical,
                exception: e
              )
              .with_context(:retry_attempts, attempt)
              .with_context(:retry_failed, true)
          end
        end
      end

      private

      def calculate_backoff(attempt)
        @backoff**attempt
      end
    end
  end
end
