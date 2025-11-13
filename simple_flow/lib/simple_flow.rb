# frozen_string_literal: true

require 'delegate'
require 'logger'
require 'tsort'

require_relative 'simple_flow/version'
require_relative 'simple_flow/error'
require_relative 'simple_flow/result'
require_relative 'simple_flow/step'
require_relative 'simple_flow/pipeline'
require_relative 'simple_flow/dag_pipeline'
require_relative 'simple_flow/step_tracker'

# Middleware
require_relative 'simple_flow/middleware/logging'
require_relative 'simple_flow/middleware/instrumentation'
require_relative 'simple_flow/middleware/retry'

##
# SimpleFlow is a modular, configurable processing framework designed for constructing and
# managing sequences of operations in a streamlined and efficient manner.
#
# ## Key Features
#
# - **Immutable Results**: All result objects are immutable, promoting safer concurrent operations
# - **Middleware Support**: Cross-cutting concerns like logging, instrumentation, and retries
# - **Flow Control**: Built-in halt/continue mechanisms for conditional execution
# - **DAG-Based Execution**: Dependency-based step ordering with parallel execution support
# - **Pipeline Composition**: Combine pipelines using the `>>` operator
# - **Named Steps**: Every step has a name for better debugging and tracking
# - **Structured Errors**: Rich error objects with severity levels and context
#
# ## Basic Usage
#
# @example Sequential Pipeline
#   pipeline = SimpleFlow::Pipeline.new do
#     use_middleware SimpleFlow::Middleware::Logging
#     step :parse, ->(result) { result.continue(parse(result.value)) }
#     step :validate, ->(result) { result.continue(validate(result.value)) }
#     step :process, ->(result) { result.continue(process(result.value)) }
#   end
#
#   result = pipeline.call(SimpleFlow::Result.new(input_data))
#
# @example DAG Pipeline with Dependencies
#   dag = SimpleFlow::DagPipeline.new do
#     step :fetch_user, ->(r) { r.continue(fetch_user(r.value)) }
#     step :fetch_posts, ->(r) { r.continue(fetch_posts(r.value)) },
#       depends_on: :fetch_user
#     step :fetch_comments, ->(r) { r.continue(fetch_comments(r.value)) },
#       depends_on: :fetch_user
#     step :combine, ->(r) { r.continue(combine(r.value)) },
#       depends_on: [:fetch_posts, :fetch_comments]
#   end
#
#   # Parallel execution where possible
#   result = dag.call_parallel(SimpleFlow::Result.new(user_id))
#
# @example Error Handling
#   pipeline = SimpleFlow::Pipeline.new do
#     step :validate, ->(result) {
#       if result.value < 0
#         result.halt.with_error(:validation, "Value must be positive", severity: :error)
#       else
#         result.continue(result.value)
#       end
#     }
#     step :process, ->(result) { result.continue(result.value * 2) }
#   end
#
#   result = pipeline.call(SimpleFlow::Result.new(-5))
#   result.failure? # => true
#   result.all_errors.first.message # => "validate: Value must be positive"
#
# @example Pipeline Composition
#   validation = SimpleFlow::Pipeline.new do
#     step :check_format, ->(r) { r.continue(check_format(r.value)) }
#   end
#
#   processing = SimpleFlow::Pipeline.new do
#     step :transform, ->(r) { r.continue(transform(r.value)) }
#   end
#
#   full_pipeline = validation >> processing
#
module SimpleFlow
  class << self
    # Creates a new sequential pipeline
    # @param name [Symbol, String, nil] optional pipeline name
    # @param block [Block] configuration block
    # @return [Pipeline] new pipeline instance
    def pipeline(name: nil, &block)
      Pipeline.new(name: name, &block)
    end

    # Creates a new DAG pipeline
    # @param name [Symbol, String, nil] optional pipeline name
    # @param block [Block] configuration block
    # @return [DagPipeline] new DAG pipeline instance
    def dag_pipeline(name: nil, &block)
      DagPipeline.new(name: name, &block)
    end

    # Creates a new result
    # @param value [Object] the initial value
    # @param options [Hash] additional options (context, errors, continue)
    # @return [Result] new result instance
    def result(value, **options)
      Result.new(value, **options)
    end
  end
end
