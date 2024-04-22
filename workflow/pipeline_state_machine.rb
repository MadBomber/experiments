require "state_machines"

module SimpleFlow
  class Pipeline
    # Represents the state of the pipeline
    attr_accessor :state

    state_machine :state, initial: :pending do
      event :advance do
        transition pending: :processing
        transition processing: :completed, if: ->(pipeline) { pipeline.all_steps_successful? }
        transition processing: :error, if: ->(pipeline) { pipeline.any_step_failed? }
      end

      event :reset do
        transition any => :pending
      end

      after_transition on: :advance, do: :execute_next_step
    end

    def initialize
      super() # Necessary to initialize state_machine
    end

    private

    def execute_next_step
      # Implementation for executing the next step based on the current pipeline state
    end

    def all_steps_successful?
      # Implementation to check if all steps were successful
    end

    def any_step_failed?
      # Implementation to check if any step failed
    end
  end
end
