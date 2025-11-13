# frozen_string_literal: true

require 'logger'

module SimpleFlow
  module Middleware
    ##
    # Logging middleware that logs step execution
    #
    class Logging
      attr_reader :logger

      # @param callable [#call] the step to wrap
      # @param logger [Logger, nil] custom logger instance
      # @param level [Symbol] log level (:debug, :info, :warn, :error)
      def initialize(callable, logger: nil, level: :info)
        @callable = callable
        @logger = logger || Logger.new($stdout)
        @level = level
      end

      def call(result)
        step_name = result.context[:current_step] || 'unknown'

        @logger.send(@level, "→ Starting step: #{step_name}")
        @logger.send(@level, "  Input value: #{result.value.inspect}")

        result = @callable.call(result)

        if result.continue?
          @logger.send(@level, "✓ Completed step: #{step_name}")
          @logger.send(@level, "  Output value: #{result.value.inspect}")
        else
          @logger.warn("✗ Step halted: #{step_name}")
          @logger.warn("  Errors: #{result.all_errors.map(&:message)}")
        end

        result
      end
    end
  end
end
