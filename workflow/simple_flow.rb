#
# SimpleFlow is a modular, configurable processing framework designed for constructing and
# managing sequences of operations in a streamlined and efficient manner. It allows for the easy
# integration of middleware components to augment functionality, such as logging and
# instrumentation, ensuring that actions within the pipeline are executed seamlessly. By
# defining steps as callable objects, SimpleFlow facilitates the customized processing of data,
# offering granular control over the flow of execution and enabling conditional continuation
# based on the outcome of each step. This approach makes SimpleFlow ideal for complex workflows
# where the orchestration of tasks, error handling, and context management are crucial.
#
module SimpleFlow
  require 'delegate'
  require 'logger'

  module MiddleWare
    class Logging
      def initialize(callable, logger = nil)
        @callable, @logger = callable, logger
      end

      def call(result)
        logger.info("Before call")
        result = @callable.call(result)
        logger.info("After call")
        result
      end

      private

      def logger
        @logger ||= Logger.new($stdout)
      end
    end

    class Instrumentation
      def initialize(callable, api_key: nil)
        @callable, @api_key = callable, api_key
      end

      def call(result)
        start_time = Time.now
        result = @callable.call(result)
        duration = Time.now - start_time
        puts "Instrumentation: #{@api_key} took #{duration}s"
        result
      end
    end
  end

  class Pipeline
    attr_reader :steps, :middlewares

    # Configurable through a block
    def initialize(&config)
      @steps = []
      @middlewares = []
      instance_eval(&config) if block_given?
    end

    # Dynamically register a middleware
    def use_middleware(middleware, options = {})
      @middlewares << [middleware, options]
    end

    def step(callable = nil, &block)
      callable ||= block
      raise ArgumentError, "Step must respond to #call" unless callable.respond_to?(:call)

      callable = apply_middleware(callable)
      @steps << callable
      self
    end


    def apply_middleware(callable)
      @middlewares.reverse_each do |middleware, options|
        if middleware.is_a?(Proc)
          # For lambda (Proc) middlewares, directly call it since it's not a class
          callable = middleware.call(callable)
        else
          callable = middleware.new(callable, **options)
        end
      end
      callable
    end



    def call(result)
      steps.reduce(result) do |res, step|
        res.continue? ? step.call(res) : res
      end
    end
  end

  class Result
    attr_reader :value, :context, :errors

    def initialize(value, context: {}, errors: {})
      @value = value
      @context = context
      @errors = errors
      @continue = true
    end

    def with_context(key, value)
      self.class.new(@value, context: @context.merge(key => value), errors: @errors)
    end

    def with_error(key, message)
      self.class.new(@value, context: @context, errors: @errors.merge(key => [*@errors[key], message]))
    end

    def halt(new_value = nil)
      @continue = false
      new_value ? with_value(new_value) : self
    end

    def continue(new_value)
      with_value(new_value)
    end

    def continue?
      @continue
    end

    private

    def with_value(new_value)
      self.class.new(new_value, context: @context, errors: @errors)
    end
  end

  class StepTracker < SimpleDelegator
    def call(result)
      result = __getobj__.call(result)
      result.continue? ? result : result.with_context(:halted_step, __getobj__)
    end
  end
end

# Usage example
pipeline = SimpleFlow::Pipeline.new do
  use_middleware SimpleFlow::MiddleWare::Instrumentation, api_key: '1234'
  use_middleware SimpleFlow::MiddleWare::Logging
  step ->(result) { puts "Processing: #{result.value}"; result }
  step ->(result) { result.continue(result.value + 1) }
end

initial_result = SimpleFlow::Result.new(0)
result = pipeline.call(initial_result)
puts "Final Result: #{result.value}"

