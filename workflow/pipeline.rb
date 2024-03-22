module SimpleFlow
  ##
  # The Pipeline class facilitates the creation and execution of a sequence of steps (or operations),
  # with the possibility of inserting middleware to modify or handle the processing in a flexible way.
  # This allows for a clean and modular design where components can be easily added, removed, or replaced
  # without affecting the overall logic flow. It is particularly useful for scenarios where a set of operations
  # needs to be performed in a specific order, and you want to maintain the capability to inject additional
  # behavior (like logging, authorization, or input/output transformations) at any point in this sequence.
  #
  # Example Usage:
  # pipeline = SimpleFlow::Pipeline.new do
  #   use_middleware SomeMiddlewareClass, option: value
  #   step ->(input) { do_something_with(input) }
  #   step AnotherCallableObject
  # end
  #
  # result = pipeline.call(initial_data)
  #
  class Pipeline
    attr_reader :steps, :middlewares

    # Initializes a new Pipeline object. A block can be provided to dynamically configure the pipeline,
    # allowing the addition of steps and middleware.
    def initialize(&config)
      @steps = []
      @middlewares = []
      instance_eval(&config) if block_given?
    end

    # Registers a middleware to be applied to each step. Middlewares can be provided as Proc objects or any
    # object that responds to `.new` with the callable to be wrapped and options hash.
    # @param [Proc, Class] middleware the middleware to be used
    # @param [Hash] options any options to be passed to the middleware upon initialization
    def use_middleware(middleware, options = {})
      @middlewares << [middleware, options]
    end

    # Adds a step to the pipeline. A step is any object that responds to `#call`, including Proc objects and lambdas.
    # @param [Proc, Object] callable an object responding to call, or nil if a block is given
    # @param block [Block] a block to use as the step if no callable is provided
    # @raise [ArgumentError] if neither a callable nor block is given, or if the provided object does not respond to call
    # @return [self] so that calls can be chained
    def step(callable = nil, &block)
      callable ||= block
      raise ArgumentError, "Step must respond to #call" unless callable.respond_to?(:call)

      callable = apply_middleware(callable)
      @steps << callable
      self
    end

    # Internal: Applies registered middlewares to a callable.
    # @param [Proc, Object] callable the target callable to wrap with middleware
    # @return [Object] the callable wrapped with all registered middleware
    def apply_middleware(callable)
      @middlewares.reverse_each do |middleware, options|
        if middleware.is_a?(Proc)
          callable = middleware.call(callable)
        else
          callable = middleware.new(callable, **options)
        end
      end
      callable
    end

    # Executes the pipeline with a given initial result. Each step is called in order, and the result of a step
    # is passed to the next. Execution can be short-circuited by a step returning an object that does not
    # satisfy a `continue?` condition.
    # @param result [Object] the initial data/input to be passed through the pipeline
    # @return [Object] the result of executing the pipeline
    def call(result)
      steps.reduce(result) do |res, step|
        res.respond_to?(:continue?) && !res.continue? ? res : step.call(res)
      end
    end
  end
end

