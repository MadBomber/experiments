# frozen_string_literal: true

require 'delegate'

module SimpleFlow
  ##
  # StepTracker wraps any callable and enriches halted results with context
  #
  # Uses the decorator pattern (via SimpleDelegator) to track where execution
  # was halted in the pipeline, useful for debugging and error handling.
  #
  # @example Usage
  #   step = ->(result) { result.halt }
  #   tracked = SimpleFlow::StepTracker.new(step)
  #   result = tracked.call(input)
  #   result.context[:halted_step] # => the original step
  #
  class StepTracker < SimpleDelegator
    # Calls the wrapped object's call method with the given result
    # @param result [Result] the result object being passed through the workflow
    # @return [Result] the modified result, potentially with :halted_step context
    def call(result)
      result = __getobj__.call(result)

      # If execution was halted, record which step caused it
      if result.respond_to?(:continue?) && !result.continue?
        result.with_context(:halted_step, __getobj__)
      else
        result
      end
    end
  end
end
