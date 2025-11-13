# frozen_string_literal: true

require_relative 'result'
require_relative 'step'
require_relative 'error'

module SimpleFlow
  ##
  # Sequential pipeline that executes steps in order with middleware support
  #
  # The Pipeline class facilitates the creation and execution of a sequence of steps,
  # with the possibility of inserting middleware to modify or handle the processing
  # in a flexible way. This allows for a clean and modular design where components
  # can be easily added, removed, or replaced without affecting the overall logic flow.
  #
  # @example Basic usage
  #   pipeline = SimpleFlow::Pipeline.new do
  #     use_middleware SimpleFlow::Middleware::Logging
  #     step :parse, ->(result) { result.continue(parse(result.value)) }
  #     step :validate, ->(result) { result.continue(validate(result.value)) }
  #   end
  #
  #   result = pipeline.call(SimpleFlow::Result.new(input_data))
  #
  class Pipeline
    attr_reader :steps, :middlewares, :name

    # Initializes a new Pipeline object
    # @param name [Symbol, String, nil] optional pipeline name
    # @param config [Block] optional block to configure the pipeline
    def initialize(name: nil, &config)
      @name = name
      @steps = []
      @middlewares = []
      @step_index = {}
      instance_eval(&config) if block_given?
    end

    # Registers a middleware to be applied to each step
    # @param middleware [Proc, Class] the middleware to be used
    # @param options [Hash] options to pass to the middleware
    # @return [self] for method chaining
    def use_middleware(middleware, **options)
      @middlewares << [middleware, options]
      self
    end

    # Adds a named step to the pipeline
    # @param name [Symbol, String] the step name
    # @param callable [Proc, #call, nil] the callable to execute
    # @param options [Hash] additional step options
    # @param block [Block] alternative way to provide the callable
    # @return [self] for method chaining
    # @raise [ConfigurationError] if neither callable nor block is provided
    def step(name, callable = nil, **options, &block)
      callable ||= block
      raise ConfigurationError, "Step must have a callable or block" unless callable

      # Wrap in Step object if not already
      step_obj = callable.is_a?(Step) ? callable : Step.new(name, callable, **options)

      # Apply middleware
      wrapped = apply_middleware(step_obj)

      @steps << wrapped
      @step_index[name.to_sym] = @steps.size - 1
      self
    end

    # Adds a conditional step that only executes if condition is met
    # @param name [Symbol, String] the step name
    # @param condition [Proc, #call] the condition to evaluate
    # @param callable [Proc, #call, nil] the callable to execute
    # @param options [Hash] additional step options
    # @param block [Block] alternative way to provide the callable
    # @return [self] for method chaining
    def step_if(name, condition, callable = nil, **options, &block)
      callable ||= block
      raise ConfigurationError, "Conditional step must have a callable or block" unless callable

      step_obj = ConditionalStep.new(name, condition, callable, **options)
      wrapped = apply_middleware(step_obj)

      @steps << wrapped
      @step_index[name.to_sym] = @steps.size - 1
      self
    end

    # Executes the pipeline with a given initial result
    # @param result [Result] the initial result to process
    # @return [Result] the final result after all steps
    def call(result)
      @steps.reduce(result) do |res, step|
        # Short-circuit if result indicates to stop
        break res unless res.continue?
        step.call(res)
      end
    end

    # Composes this pipeline with another pipeline
    # @param other [Pipeline] the pipeline to compose with
    # @return [Pipeline] a new composed pipeline
    def compose(other)
      raise ConfigurationError, "Can only compose with another Pipeline" unless other.is_a?(Pipeline)

      # Capture the variables outside the block
      combined_middlewares = @middlewares + other.middlewares
      combined_steps = @steps + other.steps
      combined_index = @step_index.merge(other.instance_variable_get(:@step_index))

      new_pipeline = self.class.new(name: :"#{@name}_composed")
      new_pipeline.middlewares = combined_middlewares
      new_pipeline.steps = combined_steps
      new_pipeline.instance_variable_set(:@step_index, combined_index)
      new_pipeline
    end

    # Alias for compose
    # @param other [Pipeline] the pipeline to compose with
    # @return [Pipeline] a new composed pipeline
    def >>(other)
      compose(other)
    end

    # Finds a step by name
    # @param name [Symbol, String] the step name
    # @return [Step, nil] the step if found
    def find_step(name)
      index = @step_index[name.to_sym]
      index ? @steps[index] : nil
    end

    # Creates a subpipeline with only specified steps
    # @param step_names [Array<Symbol, String>] the names of steps to include
    # @return [Pipeline] a new pipeline with only the specified steps
    def subpipeline(*step_names)
      # Collect the steps outside the block
      selected_steps = []
      new_index = {}

      step_names.each do |step_name|
        step = find_step(step_name)
        raise StepNotFoundError, "Step #{step_name} not found" unless step
        selected_steps << step
        new_index[step_name.to_sym] = selected_steps.size - 1
      end

      # Create new pipeline
      new_pipeline = self.class.new(name: :"#{@name}_sub")
      new_pipeline.middlewares = @middlewares.dup
      new_pipeline.steps = selected_steps
      new_pipeline.instance_variable_set(:@step_index, new_index)
      new_pipeline
    end

    # Returns the number of steps in the pipeline
    # @return [Integer] number of steps
    def size
      @steps.size
    end

    # Returns the list of step names
    # @return [Array<Symbol>] step names
    def step_names
      @steps.map { |s| s.is_a?(Step) ? s.name : :unnamed }
    end

    # String representation
    # @return [String] string representation
    def to_s
      name_str = @name ? "#{@name} " : ""
      "Pipeline<#{name_str}#{size} steps>"
    end

    protected

    attr_writer :middlewares, :steps, :step_index

    private

    # Applies registered middlewares to a callable
    # @param callable [#call] the target callable to wrap
    # @return [#call] the wrapped callable
    def apply_middleware(callable)
      @middlewares.reverse_each do |middleware, options|
        callable = if middleware.is_a?(Proc)
                     middleware.call(callable)
                   else
                     middleware.new(callable, **options)
                   end
      end
      callable
    end
  end
end
